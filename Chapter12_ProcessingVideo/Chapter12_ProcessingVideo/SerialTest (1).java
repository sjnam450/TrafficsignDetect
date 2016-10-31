package java_arduino;

import java.awt.SecondaryLoop;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.OutputStream;

import gnu.io.*;

//import gnu.io.CommPortIdentifier; 
//import gnu.io.SerialPort;
//import gnu.io.SerialPortEvent; 
//import gnu.io.SerialPortEventListener; 
import java.util.Enumeration;


public class SerialTest implements SerialPortEventListener{
	SerialPort serialPort;
	
	short messageInt;
	//"System.setProperty("gnu.io.rxtx.SerialPorts", "/dev/ttyACM0");"
        /** The port we're normally going to use. */
	private static final String PORT_NAMES[] = { 
			//"/dev/tty.usbserial-A9007UX1", // Mac OS X
			"/dev/tty.usbmodem1421"
//                        "/dev/ttyACM0", // Raspberry Pi
//			"/dev/ttyUSB0", // Linux
//			"COM3", // Windows
	};
	/**
	* A BufferedReader which will be fed by a InputStreamReader 
	* converting the bytes into characters 
	* making the displayed results codepage independent
	*/
	private BufferedReader input;
	/** The output stream to the port */
	private OutputStream output;
	/** Milliseconds to block while waiting for port open */
	private static final int TIME_OUT = 2000;
	/** Default bits per second for COM port. */
	private static final int DATA_RATE = 115200;

	public void initialize() {
                // the next line is for Raspberry Pi and 
                // gets us into the while loop and was suggested here was suggested http://www.raspberrypi.org/phpBB3/viewtopic.php?f=81&t=32186
               //System.setProperty("gnu.io.rxtx.SerialPorts", "/dev/ttyACM0");

		CommPortIdentifier portId = null;
		Enumeration portEnum = CommPortIdentifier.getPortIdentifiers();

		//First, Find an instance of serial port as set in PORT_NAMES.
		while (portEnum.hasMoreElements()) { //아두이노 포트와 내가 서버에 입력한 포트번호가 같은지 확인 
			CommPortIdentifier currPortId = (CommPortIdentifier) portEnum.nextElement();
			for (String portName : PORT_NAMES) {
				if (currPortId.getName().equals(portName)) {
					portId = currPortId; //같면 반복문 빠져나
					break;
				}
			}
		}
		if (portId == null) { //연결되어있지 않으면 포트를 찾을수 없기때문에 문장 출력 
			System.out.println("Could not find COM port.");
			return;
		}

		try { //시리얼 통신 연
			// open serial port, and use class name for the appName.
			serialPort = (SerialPort) portId.open(this.getClass().getName(),
					TIME_OUT);

			// set port parameters
			serialPort.setSerialPortParams(DATA_RATE,
					SerialPort.DATABITS_8,
					SerialPort.STOPBITS_1,
					SerialPort.PARITY_NONE);

			// open the streams
			input = new BufferedReader(new InputStreamReader(serialPort.getInputStream()));
			output = serialPort.getOutputStream();

			// add event listeners
			serialPort.addEventListener(this);
			serialPort.notifyOnDataAvailable(true);
		} catch (Exception e) {
			System.err.println(e.toString());
		}
	}

	/**
	 * This should be called when you stop using the port.
	 * This will prevent port locking on platforms like Linux.
	 */
	public synchronized void close() { //아두이노 연결 끝나면 시리얼 통신 종료 
		if (serialPort != null) {
			serialPort.removeEventListener();
			serialPort.close();
		}
	}

	/**
	 * Handle an event on the serial port. Read the data and print it.
	 */
	public synchronized void serialEvent(SerialPortEvent oEvent) {
		if (oEvent.getEventType() == SerialPortEvent.DATA_AVAILABLE) { //아두이노에서 값을 보내줘야 작동 
			try {
				String inputLine=input.readLine();
				int a = input.read();
				output.write(messageInt);	//TCPServer에서 받은 메세지에 따라 저장한 값 아두이노에 전달 
			} catch (Exception e) {
				System.err.println(e.toString());
			}
		}
		// Ignore all the other eventTypes, but you should consider the other ones.
	}

	public static void main(String[] args) throws Exception {
		SerialTest main = new SerialTest();
		main.initialize();
		
		TCPServer tcp = new TCPServer();
		tcp.serial = main;
        Thread desktopServerThread = new Thread(tcp);
        desktopServerThread.start();
		System.out.println("Started");
	}
}