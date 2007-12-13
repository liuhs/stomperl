package org.thoughtworkers.stomperl.acceptance;

import java.util.HashMap;
import java.util.Map;

import junit.framework.TestCase;
import net.ser1.stomp.Client;
import net.ser1.stomp.Listener;
import net.ser1.stomp.Stomp;

public class SampleClient extends TestCase {
	private static final int PORT = 61613;

	private Map<String, StringBuffer> subscribe(Stomp c, String destination) {
		final HashMap<String, StringBuffer> res = new HashMap<String, StringBuffer>();
		StringBuffer buff = new StringBuffer();
		res.put("MESSAGE", buff);
		c.subscribe(destination, new Listener() {
			@SuppressWarnings("unchecked")
			public void message(Map h, String b) {
				System.out.println("MESSAGE: " + b);
				res.get("MESSAGE").append(b);
			}
		});
		return res;
	}

	public void testTalkToExistingServer() throws Exception {
		System.out.println("testTalkToExistingServer");
		
		Client c1 = new Client("localhost", PORT, "user1", "pass1");
		Client c2 = new Client("localhost", PORT, "user2", "pass2");
		
		Map<String, StringBuffer> res = subscribe(c1, "a");
		Thread.sleep(200);

		c2.begin();
		c2.send("a", "123");
		c2.send("a", "456");
		c2.send("a", "789");
		c2.commit();

		Thread.sleep(500);
		assertEquals("123456789", res.get("MESSAGE").toString());
		
		c1.disconnect();
		c2.disconnect();
	}
	
	public void testTransaction() throws Exception {
		System.out.println("testTransaction");
		
		Client c1 = new Client("localhost", PORT, "user1", "pass1");
		Client c2 = new Client("localhost", PORT, "user2", "pass2");
		
		Map<String, StringBuffer> res = subscribe(c1, "a");
		Thread.sleep(200);
		
		c2.begin();
		c2.send("a", "123");
		c2.send("a", "456");
		c2.send("a", "789");
		c2.commit();
		
		c2.begin();
		c2.send("a", "123");
		c2.send("a", "456");
		c2.send("a", "789");
		c2.abort();
		
		Thread.sleep(500);
		assertEquals("123456789", res.get("MESSAGE").toString());
		
		c1.disconnect();
		c2.disconnect();
	}
	
	public void testUnsubscribe() throws Exception {
		System.out.println("testUnsubscribe");

		Client c1 = new Client("localhost", PORT, "user1", "pass1");
		Client c2 = new Client("localhost", PORT, "user2", "pass2");
		
		Map<String, StringBuffer> res = subscribe(c1, "a");
		Thread.sleep(200);
		
		c2.send("a", "123");
		Thread.sleep(200);

		c1.unsubscribe("a");
		Thread.sleep(200);
		
		c2.send("a", "456");
		
		Thread.sleep(500);
		assertEquals("123", res.get("MESSAGE").toString());
		
		c1.disconnect();
		c2.disconnect();
	}
	
	public void testDisconnect() throws Exception {
		System.out.println("testDisconnect");
		Client client = new Client("localhost", PORT, "user", "pass");
		assertTrue(client.isConnected());
		client.disconnect();
		assertTrue(client.isClosed());
		assertFalse(client.isConnected());
	}
	
	public void testAskForReceipt() throws Exception {
		System.out.println("testAskForReceipt");
		Client client = new Client("localhost", PORT, "user", "pass");
		HashMap<String, String> header = new HashMap<String, String>();
		client.sendW("test", "message needs receipt", header);
		assertTrue(client.hasReceipt(header.get("receipt")));
		client.disconnect();
	}

}
