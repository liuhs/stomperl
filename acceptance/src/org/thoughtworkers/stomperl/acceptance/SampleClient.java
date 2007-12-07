package org.thoughtworkers.stomperl.acceptance;

import java.util.HashMap;
import java.util.Map;

import junit.framework.TestCase;
import net.ser1.stomp.Client;
import net.ser1.stomp.Listener;
import net.ser1.stomp.Stomp;

public class SampleClient extends TestCase {
	private static final int PORT = 61613;

	private Map<String, StringBuffer> subscribe(Stomp c, String channel) {
		final HashMap<String, StringBuffer> res = new HashMap<String, StringBuffer>();
		StringBuffer buff = new StringBuffer();
		res.put("MESSAGE", buff);
		c.subscribe(channel, new Listener() {
			@SuppressWarnings("unchecked")
			public void message(Map h, String b) {
				System.out.println("MESSAGE: " + b);
				res.get("MESSAGE").append(b);
			}
		});
		return res;
	}

	public void testTalkToExistingServer() throws Exception {
		Client c1 = new Client("localhost", PORT, "user1", "pass1");
		Client c2 = new Client("localhost", PORT, "user2", "pass2");
		
		Map<String, StringBuffer> res = subscribe(c1, "a");
		Thread.sleep(200);

//		c2.begin(makeTxHeader());
		c2.send("a", "123");
		c2.send("a", "456");
//		c2.commit(makeTxHeader());

		Thread.sleep(500);
		assertEquals("123456", res.get("MESSAGE").toString());
	}

	private Map<String, Integer> makeTxHeader() {
		Map<String, Integer> header = new HashMap<String, Integer>();
		header.put("transaction", 123);
		return header;
	}
}
