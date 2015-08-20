[Stomp](http://stomp.codehaus.org/) is a simple text oriented messaging protocol. Stomperl is an implementation of Stomp broker with [Erlang](http://erlang.org/). That means **performance**, **scalability**, **reliability** and **elegance** in concurrent programming are our goals.

Stomperl stole its architecture and initial code base from following articles:

  * [Building a Non-blocking TCP server using OTP principles](http://www.trapexit.org/Building_a_Non-blocking_TCP_server_using_OTP_principles)
  * [supervisor の simple\_one\_for\_one を使って echoserver を書き直した](http://d.hatena.ne.jp/cooldaemon/20071024/1193193093) - for those who don't understand Japanese: I don't either, and it doesn't matter.

The picture below shows current architecture of Stomperl.

```
                 +----------------+
                 | tcp_server_sup |
                 +--------+-------+
                          | (one_for_one)
         +----------------+---------+
         |                          |
 +-------+------+           +-------+--------+
 | tcp_acceptor |           + tcp_client_sup |
 +--------------+           +-------+--------+
                                    | (simple_one_for_one)
                              +-----|---------+
                            +-------|--------+|
                           +--------+-------+|+
                           |    tcp_stomp   |+
                           +--------+-------+
                                    | (one for each)
                            +-------+--------+
                            |     mailer     |
                            +-------+--------+
```

Check out the [project wiki](http://code.google.com/p/stomperl/wiki/ReadMe) for more information.