module wings.asyncprocess;	// Created on 30-Dec-2023 4:03:14 PM

import std.process;

alias ProcessHandler = void delegate(string value);

class AsyncProcess
{
    this()
    {
        this.mStdErr = pipe();
        this.mStdIn = pipe();
        this.mStdOut = pipe();
    }

    this(string cmd, ProcessHandler stdoutHandler = null, ProcessHandler stderrHandler = null)
    {
        this();
        this.onStdErr = stderrHandler;
        this.onStdOut = stdoutHandler;
        this.mCmd = cmd;
    }

    void start()
    {
        char[] line;
        auto x = spawnShell(this.mCmd, this.mStdIn.readEnd, this.mStdOut.writeEnd, this.mStdErr.writeEnd,
							null, Config.detached | Config.suppressConsole);
        while (!this.mStdErr.readEnd.eof) {
            size_t nb = this.mStdErr.readEnd.readln(line);
        }
    }

    private:
    string mCmd
    Pipe mStdIn;
    Pipe mStdOut;
    Pipe mStdErr;
    ProcessHandler onStdOut;
    ProcessHandler onStdErr;
}