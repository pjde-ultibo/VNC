program VNCTest;

{$mode objfpc}{$H+}

{$define use_tftp}
{$hints off}
{$notes off}

uses
  RaspberryPi3,
  GlobalConfig,
  GlobalConst,
  GlobalTypes,
  Platform,
  Threads,
  SysUtils,
  Classes,
  Console,
  Ultibo, uVNC, uCanvas,
{$ifdef use_tftp}
  uTFTP, Winsock2,
{$endif}
  uLog
  { Add additional units here };

type

  { THelper }
  THelper = class
    procedure VNCPointer (Sender : TObject; Thread : TVNCThread; x, y : TCard16; BtnMask : TCard8);
    procedure VNCKey (Sender : TObject; Thread : TVNCThread; Key : TCard32; Down : boolean);
  end;

var
  Console1, Console2, Console3 : TWindowHandle;
  ch : char;
  IPAddress : string;
  Helper : THelper;
  aVNC : TVNCServer;

procedure Log1 (s : string);
begin
  ConsoleWindowWriteLn (Console1, s);
end;

procedure Log2 (s : string);
begin
  ConsoleWindowWriteLn (Console2, s);
end;

procedure Log3 (s : string);
begin
  ConsoleWindowWriteLn (Console3, s);
end;

procedure Msg2 (Sender : TObject; s : string);
begin
  Log2 ('TFTP - ' + s);
end;

procedure WaitForSDDrive;
begin
  while not DirectoryExists ('C:\') do sleep (500);
end;

function WaitForIPComplete : string;
var
  TCP : TWinsock2TCPClient;
begin
  TCP := TWinsock2TCPClient.Create;
  Result := TCP.LocalAddress;
  if (Result = '') or (Result = '0.0.0.0') or (Result = '255.255.255.255') then
    begin
      while (Result = '') or (Result = '0.0.0.0') or (Result = '255.255.255.255') do
        begin
          sleep (1000);
          Result := TCP.LocalAddress;
        end;
    end;
  TCP.Free;
end;

{ THelper }

procedure THelper.VNCPointer (Sender: TObject; Thread: TVNCThread; x,
  y: TCard16; BtnMask: TCard8);
begin
  ConsoleWindowSetXY (Console3, 1, 1);
  Consolewindowwrite (Console3, IntToStr (x) + ',' + IntToStr (y) + ' Btns ' + BtnMask.ToHexString (2) + '    ');
end;

procedure THelper.VNCKey (Sender: TObject; Thread: TVNCThread; Key: TCard32;
  Down: boolean);
begin
  ConsoleWindowSetXY (Console3, 1, 2);
  Consolewindowwrite (Console3, IntToStr (Key) + ' Down ' + ft[Down] + '    ');
end;



begin
  Console1 := ConsoleWindowCreate (ConsoleDeviceGetDefault, CONSOLE_POSITION_LEFT, true);
  Console2 := ConsoleWindowCreate (ConsoleDeviceGetDefault, CONSOLE_POSITION_TOPRIGHT, false);
  Console3 := ConsoleWindowCreate (ConsoleDeviceGetDefault, CONSOLE_POSITION_BOTTOMRIGHT, false);
  SetLogProc (@Log1);
  Log1 ('VNC Server Test.');
  Log1 ('2018 pjde.');

  Log3 ('');
  WaitForSDDrive;
  Log1 ('SD Drive Ready.');
  IPAddress := WaitForIPComplete;
  Log1 ('Run VNC Viewer and point to ' + IPAddress);

{$ifdef use_tftp}
  Log2 ('TFTP - Enabled.');
  Log2 ('TFTP - Syntax "tftp -i ' + IPAddress + ' PUT kernel7.img"');
  SetOnMsg (@Msg2);
  Log2 ('');
{$endif}

  aVNC := TVNCServer.Create;
  Helper := THelper.Create;
  aVNC.OnKey := @Helper.VNCKey;
  aVNC.OnPointer := @Helper.VNCPointer;
  aVNC.InitCanvas (640, 480);
  aVNC.Canvas.Fill (COLOR_RED);
  aVNC.Canvas.Fill (SetRect (50, 50, 100, 200), COLOR_GREEN);
  aVNC.Canvas.Fill (SetRect (200, 50, 250, 300), COLOR_BLUEIVY);
  aVNC.Canvas.DrawText (40, 40, 'ULTIBO VNC TEST.', 'arial', 24, COLOR_WHITE);
  aVNC.Canvas.DrawText (40, 100, 'THIS IS A CANVAS.', 'arial', 24, COLOR_WHITE);
  aVNC.Canvas.DrawText (40, 160, 'THIS IS NOT THE FRAMEBUFFER.', 'arial', 24, COLOR_WHITE);
  aVNC.Title := 'Test of Ultibo VNC Server';;
  aVNC.Active := true;
  ch := #0;
  while true do
    begin
      if ConsoleGetKey (ch, nil) then
        case (ch) of
          '1' : aVNC.Active := true;
          '2' : aVNC.Active := false;
          end;
    end;
  ThreadHalt (0);
end.

