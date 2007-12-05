-module(stomp_frame).

-include_lib("eunit/include/eunit.hrl").

parse(FrameText) ->
	Parts = split_frame(FrameText),
	Envelope = lists:nth(1, Parts),
	Body = lists:nth(2, Parts),
	
	Tokens = string:tokens(Envelope, "\r\n"),
	Command = lists:nth(1, Tokens),
	Headers = parse_headers(lists:delete(Command, Tokens)),
	{frame, Command, Headers, Body}.

split_frame(FrameText) ->
	SplitLocation = string:str(FrameText, "\r\n\r\n"),
	Envelope = string:substr(FrameText, 1, SplitLocation - 1),
	Body = string:substr(FrameText, SplitLocation + 4),
	[Envelope, Body].

parse_headers([]) -> [];
parse_headers([HeaderText | Others]) ->
	Tokens = string:tokens(HeaderText, ":"),
	Key = lists:nth(1, Tokens),
	Value = lists:nth(2, Tokens),
	[{Key, Value} | parse_headers(Others)].

get_command({frame, Command, _Headers, _Body}) -> Command.
get_headers({frame, _Command, Headers, _Body}) -> Headers.
get_body({frame, _Command, _Headers, Body}) -> Body.

%% Tests

simple_frame_test_() ->
	FrameText = "COMMAND\r\nname:value\r\nfoo:bar\r\n\r\nmessage body\r\n",
	Frame = parse(FrameText),
	Command = get_command(Frame),
	Headers = get_headers(Frame),
	Body = get_body(Frame),
	[
	?_assertMatch("COMMAND", Command),
	?_assertMatch([{"name", "value"}, {"foo", "bar"}], Headers),
	?_assertMatch("message body\r\n", Body),
	?_assertMatch(1, 1)
	].

parse_headers_test_() ->
	Headers = parse_headers(["name:value", "foo:bar"]),
	[
	?_assertMatch([{"name", "value"}, {"foo", "bar"}], Headers)
	].
	
split_frame_test_() ->
	FrameText = "COMMAND\r\nname:value\r\nfoo:bar\r\n\r\nmessage body\r\n\000\r\n",
	Envelope = lists:nth(1, split_frame(FrameText)),
	[
	?_assertMatch("COMMAND\r\nname:value\r\nfoo:bar", Envelope)
	].