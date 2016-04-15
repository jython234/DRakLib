﻿module draklib.server.RakNetServer;
import std.conv;
import std.random;
import std.datetime;
import std.exception;

import core.thread;

import draklib.DRakLib;
import draklib.server.RakSocket;
import draklib.util.Logger;
import draklib.util.misc;
import draklib.util.exception;

/**
 * Struct which contains all the server's options that
 * can be configured.
 */
struct ServerOptions {
	// The name of the server which will be broadcasted on the network
	public string broadcastName = "A DRakLib Server";

	// Maximum amount of packets to be handled per tick (20 ticks per second)
	public uint maxPacketsPerTick = 500;

	public uint recvBufferSize = 4096;
	public uint sendBufferSize = 4096;
	public uint packetTimeout = 5000;
	public bool portChecking = true;
	/**
     * If this is true then the server will disconnect clients with invalid raknet protocols.
     * The server currently supports protocol 7
     */
	public bool disconnectInvalidProtocol = true;
	/**
     * If to log warning messages when a tick takes longer than 50 milliseconds.
     */
	public bool warnOnCantKeepUp = true;
	/**
     * The server's unique 64 bit identifier. This is usually generated
     * randomly at start. If negative, the server will randomly generate the number.
     */
	public long serverID = -1;
}

class RakNetServer {
	private bool crashed = false;
	private bool running = false;

	private Logger logger;
	private ServerOptions options;
	private RakSocket socket;

	this(Logger logger, ushort bindPort, string bindIp = "0.0.0.0", ServerOptions options = ServerOptions()) {
		socket = new RakSocket(bindIp, bindPort);
		this.options = options;
		this.logger = logger;

		if(this.options.serverID == -1) {
			auto rn = Random();
			this.options.serverID = uniform(0L, long.max, rn); // Generate serverId
		}
	}

	public void start() {
		enforce(this.running != true, new IllegalOperationException("Server is already running!"));
		this.running = true;
		run();
	}

	public void stop() {
		enforce(this.running == true, new IllegalOperationException("Server is not running!"));
		this.running = false;
	}

	private void run() {
		logger.logDebug("Starting RakNetServer implementing RakNet protocol: " ~ to!string(DRakLib.RAKNET_VERSION) ~ ", serverID is: " ~ to!string(options.serverID));
		try {
			socket.bind();
		} catch(Exception e) {
			logger.logError("Failed to bind to " ~ socket.getBindIP() ~ ":" ~ socket.getBindPort().stringof ~ ": " ~ e.info.toString());
			crashed = true;
			running = false;
			return;
		}
		logger.logInfo("Server started on " ~ socket.getBindIP() ~ ":" ~ socket.getBindPort().stringof);

		while(running) {
			long start = getTime();
			doTick();
			long elapsed = getTime() - start;
			if(elapsed > 50 && options.warnOnCantKeepUp) {
				logger.logWarn("Can't keep up! (" ~ elapsed.stringof ~ ">50) Did the system time change or is the server overloaded?");
			} else if(elapsed < 50) {
				Thread.sleep(dur!("msecs")( 50 - elapsed));
			}
		}
	}

	private void doTick() {
		//TODO
	}

	public string getBindIp() {
		return socket.getBindIP();
	}

	public ushort getBindPort() {
		return socket.getBindPort();
	}
}