-module(stomp_frame).

-include_lib("eunit/include/eunit.hrl").

-export([parse_frames/1, get_command/1, get_body/1, get_header/2, get_header/3, new/3, to_text/1]).

parse_frames(List=[_|_])->    
    parse(List,"",{frame,[],[],[]},[]).
parse([$\n |T],Command,_,Frames)->    
    parse_head(T,{"",""},{frame,lists:reverse(Command),[],[]},Frames);
parse([],_,_,Frames)->        
    Frames;    
parse([H|T],Command,Result,Frames)->
    parse(T,[H|Command],Result,Frames).
parse_head([$:|T],{First,Second},Result,Frames)->    
    parse_head(T,{Second,First},Result,Frames);
parse_head([],{First,Second},{frame,Command,Headers,Body},Frames)->             
    [{frame,Command,[{convert(First),convert(Second)}|Headers],Body}|Frames];
parse_head([$\n,$\n|T],{First,Second},{frame,Command,Headers,Body},Frames)->             
    parse_body(T,"",{frame,Command,[{convert(First),convert(Second)}|Headers],Body},Frames);
parse_head([$\n|T],{First,Second},{frame,Command,Headers,[]},Frames)->        
    parse_head(T,{"",""},{frame,Command,[{convert(First),convert(Second)}|Headers],[]},Frames);
parse_head([H|T],{First,Second},Result,Frames)->    
    parse_head(T,{First,[H|Second]},Result,Frames).
parse_body([H,0,$\n|T],B,Result,Frames)-> 
    parse(T,"",{frame,[],[],[]},[setelement(4,Result,convert([H|B]))|Frames]);      
parse_body([H,$\n],B,Result,Frames)->           
    [setelement(4,Result,convert([H|B]))|Frames];
parse_body([H|T],B,Result,Frames)->         
    parse_body(T,[H|B],Result,Frames).

convert([$\n|T])->lists:reverse(T);
convert(Str)->lists:reverse(Str).

get_command({frame,Command,_,_}) -> Command.
get_headers({frame,_,Headers,_}) -> Headers.
get_body({frame,_,_, Body}) -> Body.

get_header(Frame, Key) ->	
        case lists:keysearch(Key, 1, get_headers(Frame)) of
            {value,{_,Value}}->Value;
            false->undefined
        end.
get_header(Frame, Key, Default) ->
	case get_header(Frame, Key) of
		undefined -> Default;
		Value -> Value
         end.


new(Command, Headers, Body) -> {frame, Command, Headers, Body}.
to_text({frame, Command, Headers, Body}) ->lists:concat(
	[Command,"\n",lists:concat(lists:foldl(fun({Key,Value},ACC)->
             [Key,":",Value,"\n"|ACC]end,"",Headers)),"\n", Body,"\000","\n"]).
        
frames_to_text(Frames) ->lists:concat(
    lists:foldl(fun(Frame,Acc)->[to_text(Frame)|Acc] end,"",Frames)).

%% Tests

simple_frame_test_() ->
	FrameText = "COMMAND\nname:value\nfoo:bar\n\nmessage\nbody\n",
	[Frame|_] = parse_frames(FrameText),
	Command = get_command(Frame),
	Headers = get_headers(Frame),
	Body = get_body(Frame),
	[
	?_assertMatch("COMMAND", Command),
	?_assertMatch([{"foo", "bar"},{"name", "value"}], Headers),
	?_assertMatch("message\nbody", Body),
	?_assertMatch(1, 1)
	].

get_header_test_() ->
	FrameText = "COMMAND\nname:value\nfoo:bar\n\nmessage body\n",
	[Frame|_] = parse_frames(FrameText),
	[
	?_assertMatch("value", get_header(Frame, "name")),
	?_assertMatch("bar", get_header(Frame, "foo")),
	?_assertMatch(undefined, get_header(Frame, "not_exist")),
	?_assertMatch("default", get_header(Frame, "not_exist", "default"))
	].

parse_multi_frame_test_() ->
	Text = "C1\nname:value\n\nmessage1\n\000\nC2\nfoo:bar\n\nmessage2\n\000\n",
	[Frame2, Frame1] = parse_frames(Text),
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
	[Frame|_] = parse_frames(Text),
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
	Frame = new("COMMAND", [{"key", "value"}, {"foo", "bar"}], "aaa"),
	Text = to_text(Frame),        
        Result=parse_frames(Text),        
	[
	?_assertMatch([Frame],Result)
	].
	
frames_to_text_test_() ->
	Text = "C1\nname:value\n\nmessage1\000\nC2\nfoo:bar\n\nmessage2\000\n",
	Frames = parse_frames(Text),
        [
	?_assertMatch(Text, frames_to_text(Frames))
	].