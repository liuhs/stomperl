-module(stomp_frame).

-include_lib("eunit/include/eunit.hrl").

-export([parse_frames/1, get_command/1, get_body/1, get_header/2, get_header/3, new/3, to_text/1]).

parse(Text) -> lists:nth(1, parse_frames(Text)).

parse_single_frame(FrameText) ->
	Parts = split_frame(FrameText),
	Envelope = lists:nth(1, Parts),
	Body = lists:nth(2, Parts),
	
	Tokens = string:tokens(Envelope, "\n"),
	Command = lists:nth(1, Tokens),
	Headers = parse_headers(lists:delete(Command, Tokens)),
	{frame, Command, Headers, Body}.

parse_frames(Text) ->
	FrameTexts = lists:map(fun strip_new_line/1, extract_frames(Text)),
	lists:map(fun parse_single_frame/1, FrameTexts).

split_frame(FrameText) ->
	SplitLocation = string:str(FrameText, "\n\n"),
	case SplitLocation of
		0 ->
			[FrameText, ""];  %% envelope only
		_ ->
			Envelope = string:substr(FrameText, 1, SplitLocation - 1),
			Body = string:substr(FrameText, SplitLocation + 2),
			[Envelope, Body]
	end.

parse_headers([]) -> [];
parse_headers([HeaderText | Others]) ->
	Tokens = string:tokens(HeaderText, ":"),
	Key = lists:nth(1, Tokens),
	Value = lists:nth(2, Tokens),
	[{Key, Value} | parse_headers(Others)].

get_command({frame, Command, _Headers, _Body}) -> Command.
get_headers({frame, _Command, Headers, _Body}) -> Headers.
get_body({frame, _Command, _Headers, Body}) -> Body.

get_header(Frame, Key) ->
	Headers = get_headers(Frame),
	Pairs = lists:filter(fun({K, _V}) -> K == Key end, Headers),
	case Pairs of
		[] -> undefined; 
		[{_Key, Value} | _] -> Value;
		_Other -> erlang:error("frame structure error")
	end.

get_header(Frame, Key, Default) ->
	case get_header(Frame, Key) of
		undefined -> Default;
		Value -> Value
	end.

extract_frames(Text) ->	string:tokens(strip_new_line(Text), "\000").
strip_new_line(Text) -> string:strip(Text, both, $\n).

new(Command, Headers, Body) -> {frame, Command, Headers, Body}.
to_text({frame, Command, Headers, Body}) ->
	Command ++ "\n" ++ headers_to_text(Headers) ++ "\n" ++ Body ++ "\000\n".

header_to_text({Key, Value}) -> Key ++ ":" ++ Value ++ "\n".

headers_to_text([]) -> "";
headers_to_text([Header | Others]) -> header_to_text(Header) ++ headers_to_text(Others).

frames_to_text([]) -> "";
frames_to_text([Frame | Others]) -> to_text(Frame) ++ frames_to_text(Others).

%% Tests

simple_frame_test_() ->
	FrameText = "COMMAND\nname:value\nfoo:bar\n\nmessage\nbody\n",
	Frame = parse(FrameText),
	Command = get_command(Frame),
	Headers = get_headers(Frame),
	Body = get_body(Frame),
	[
	?_assertMatch("COMMAND", Command),
	?_assertMatch([{"name", "value"}, {"foo", "bar"}], Headers),
	?_assertMatch("message\nbody", Body),
	?_assertMatch(1, 1)
	].

get_header_test_() ->
	FrameText = "COMMAND\nname:value\nfoo:bar\n\nmessage body\n",
	Frame = parse(FrameText),
	[
	?_assertMatch("value", get_header(Frame, "name")),
	?_assertMatch("bar", get_header(Frame, "foo")),
	?_assertMatch(undefined, get_header(Frame, "not_exist")),
	?_assertMatch("default", get_header(Frame, "not_exist", "default"))
	].

parse_headers_test_() ->
	Headers = parse_headers(["name:value", "foo:bar"]),
	[
	?_assertMatch([{"name", "value"}, {"foo", "bar"}], Headers)
	].
	
split_frame_test_() ->
	FrameText = "COMMAND\nname:value\nfoo:bar\n\nmessage body\n\000\n",
	Envelope = lists:nth(1, split_frame(FrameText)),
	[
	?_assertMatch("COMMAND\nname:value\nfoo:bar", Envelope)
	].
	
extract_multi_frame_test_() ->
	Text = "C1\nname:value\n\nmessage1\n\000\nC2\nfoo:bar\n\nmessage2\n\000\n",
	[
	?_assertMatch([_, _], extract_frames(Text)) 
	].
	
parse_multi_frame_test_() ->
	Text = "C1\nname:value\n\nmessage1\n\000\nC2\nfoo:bar\n\nmessage2\n\000\n",
	[Frame1, Frame2] = parse_frames(Text),
	[
	?_assertMatch("C1", get_command(Frame1)),
	?_assertMatch("value", get_header(Frame1, "name")),
	?_assertMatch("message1", get_body(Frame1)),
	?_assertMatch("C2", get_command(Frame2)),
	?_assertMatch("bar", get_header(Frame2, "foo")),
	?_assertMatch("message2", get_body(Frame2)),
	?_assertMatch(1, 1)
	].

envelope_only_frame_test_() ->
	Text = "CONNECT\npasscode:pass1\nlogin:user1",
	Frame = parse(Text),
	[
	?_assertMatch("CONNECT", get_command(Frame)),
	?_assertMatch("pass1", get_header(Frame, "passcode")),
	?_assertMatch("user1", get_header(Frame, "login"))
	].
	
create_frame_test_() ->
	Frame = new("COMMAND", [{"key", "value"}, {"foo", "bar"}], "message body"),
	[
	?_assertMatch("COMMAND", get_command(Frame)),
	?_assertMatch("value", get_header(Frame, "key")),
	?_assertMatch("bar", get_header(Frame, "foo")),
	?_assertMatch("message body", get_body(Frame))
	].
	
frame_to_text_test_() ->
	Frame = new("COMMAND", [{"key", "value"}, {"foo", "bar"}], "message body"),
	Text = to_text(Frame),
	[
	?_assertMatch(Frame, parse(Text))
	].
	
frames_to_text_test_() ->
	Text = "C1\nname:value\n\nmessage1\000\nC2\nfoo:bar\n\nmessage2\000\n",
	Frames = parse_frames(Text),
	[
	?_assertMatch(Text, frames_to_text(Frames))
	].