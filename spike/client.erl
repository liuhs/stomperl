-module(client).
-compile(export_all).

client() ->
    SomeHostInNet = "localhost",
    {ok, Sock} = gen_tcp:connect(SomeHostInNet, 61613, [binary, {packet, 0}]),
    ok = gen_tcp:send(Sock, "abc\n\0"),
    ok = gen_tcp:send(Sock, "edf\n\0"),
    ok = gen_tcp:close(Sock).