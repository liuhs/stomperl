use Net::Stomp;

my $client1 = Net::Stomp->new( { hostname => 'localhost', port => '61613' } );
my $client2 = Net::Stomp->new( { hostname => 'localhost', port => '61613' } );
my $client3 = Net::Stomp->new( { hostname => 'localhost', port => '61613' } );

$client1->connect( { login => 'user1', passcode => 'pass1' } );
$client1->send(
    { destination => 'queue^/queue/foo', body => 'test message' } );
$client1->send(
    { destination => 'queue^/queue/foo', body => 'another test message' } );

$client2->connect( { login => 'user2', passcode => 'pass2' } );
$client2->subscribe(
    {   destination             => 'queue^/queue/foo',
        'ack'                   => 'client'
    }
);

$client3->connect( { login => 'user3', passcode => 'pass2' } );
$client3->subscribe(
    {   destination             => 'queue^/queue/foo',
        'ack'                   => 'client'
    }
);

my $frame1 = $client2->receive_frame;
assert_equals("test message", $frame1->body);
$client2->ack( { frame => $frame1 } );

my $frame2 = $client3->receive_frame;
assert_equals("another test message", $frame2->body);
$client3->ack( { frame => $frame2 } );

$client1->disconnect;
$client2->disconnect;
$client3->disconnect;

sub assert_equals{
	my $expected = $_[0]; 
	my $actual = $_[1];
	if($expected eq $actual) {
		print ".";
		return;
	}
	die "Failure: expected [$expected] but got [$actual]\n";
}
