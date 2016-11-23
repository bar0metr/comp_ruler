unit main;

{$mode objfpc}{$H+}

interface

uses

  Classes, SysUtils, sqldb, db, mysql55conn, FileUtil, Forms, Controls,
  Graphics, Dialogs, ComCtrls, Process, ExtCtrls, StdCtrls, PingThread;

type

  { Tmainform }

  Tmainform = class(TForm)
    DataSource1: TDataSource;
    MySQL55Connection1: TMySQL55Connection;
    ScrollBox1: TScrollBox;
    SQLQuery1: TSQLQuery;
    SQLTransaction1: TSQLTransaction;
    StatusBar1: TStatusBar;
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ScrollBox1Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Vnc_open(Sender: TObject);
  private
    { private declarations }
  public
        procedure get_computers;
        procedure pinger;
  end;

type Tpings = record
   isping: boolean;
 end;
  type TComputers = record
   comp_: string;
 end;

var
  mainform: Tmainform;
  ThreadArray: Array of TPingThread;
  Ping: Array of TPingResult;
  ThreadsComplete,pinger_complete:Boolean;
  indicator: TShape;
  cname: TLabel;
  compcount: integer;
  top_comp: integer;
  pings: array of TPings;
  computers: array of TComputers;
  computer: integer;
  pathexe: string;
 // pingthreades: array of TMyThread;
implementation

{$R *.lfm}


procedure Tmainform.get_computers;
var
  i: integer;
begin
  StatusBar1.Panels[1].Text:='Подключение...   ';
   try
    MySQL55Connection1.Connected:=true;
  except
    ShowMessage(' Не могу подключиться к базе данных');
  exit;
  end;
  try
    SQLTransaction1.Active:=true;
  except
    ShowMessage(' Не могу создать транзакцию');
  exit;
  end;
  try
   StatusBar1.Panels[1].Text:='Считывание...   ';
   SQLQuery1.Active:=false;
    {$ifdef unix}
   SQLQuery1.SQL.Clear;
   sqlquery1.SQL.Add('SET character_set_client="utf8", character_set_connection="utf8",character_set_results="utf8";');
   SQLQuery1.ExecSQL;

   {$endif}
   SQLQuery1.SQL.Clear;
   sqlquery1.SQL.Add('SELECT * FROM users;');
   SQLQuery1.open;
   compcount:= sqlquery1.RecordCount;
   //showmessage(inttostr(compcount));
   SetLength(pings,compcount);
   SetLength(Ping,compcount);
   SetLength(ThreadArray,compcount);
   sqlquery1.First;
   StatusBar1.Panels[1].Text:='Построение списка...   ';
   for i:= 1 to compcount do
   begin
      indicator:= TShape.Create(ScrollBox1);
      indicator.Parent:=ScrollBox1;
      indicator.Shape:= stCircle;
      indicator.Brush.Color:= clMedGray;
      indicator.Left:=8;
      indicator.Top:=top_comp+2;
      indicator.Width:=12;
      indicator.Height:=12;
      indicator.Name:= 'led'+inttostr(i);


      cname:= TLabel.Create(ScrollBox1);
      cname.Parent:=ScrollBox1;
      cname.Left:=24;
      cname.Top:=top_comp+1;
      cname.Width:=12;
      cname.Height:=12;
      cname.Caption:= sqlquery1.fields[1].AsString;
      cname.hint:= sqlquery1.fields[2].AsString;
      cname.ShowHint:= true;
      cname.OnDblClick:= @Vnc_open;

      Ping[i-1].IPAdress  := sqlquery1.fields[2].AsString;
      Ping[i-1].Exists    := false;
      top_comp:= top_comp+20;
      sqlquery1.Next;
   end;
  except
    ShowMessage(' Ошибка при выполнении SQL запроса.');
  exit;
  end;
   StatusBar1.Panels[1].Text:='Готово...   ';
  // pinger.

end;
{ Tmainform }

procedure TMainform.pinger;
var
  i: integer;
begin

   pinger_complete:= false;

   application.ProcessMessages;
  for i:= 1 to compcount do
  begin
   ThreadArray[i-1] := TPingThread.Create(Ping[i-1]);
  end;
   repeat
          ThreadsComplete := true;
         // Write('.');
         // Sleep(1000);
          for i := 0 to compcount-1 do
            begin
              if not ThreadArray[i].Ready
                then
                  begin
                    ThreadsComplete := false;
                    break;
                  end;
            end;
        until ThreadsComplete;

        // Show Results to User
        for i := 0 to compcount-1 do
          begin
            if ThreadArray[i].PingResult.Exists
              then
                begin
                  (ScrollBox1.FindComponent('led'+inttostr(i+1)) as TShape).Brush.Color:= cllime
      end
            else
                  (ScrollBox1.FindComponent('led'+inttostr(i+1)) as TShape).Brush.Color:= clred;
            end;
        // Free Threads
        for i := 0 to compCount-1 do
          begin
            ThreadArray[i].Free;
          end;
       application.ProcessMessages;
       pinger_complete:= true;
       statusbar1.Panels[1].Text := 'Пропинговано...     '
end;

procedure Tmainform.ScrollBox1Click(Sender: TObject);
begin

end;

procedure Tmainform.Timer1Timer(Sender: TObject);
begin
   statusbar1.Panels[1].Text := 'In Progress...     ';
  if  pinger_complete then
    begin
        pinger;
    end
  else statusbar1.Panels[1].Text := 'Пропинговано...     ';

end;



procedure Tmainform.FormCreate(Sender: TObject);
begin
  pathexe:= includetrailingbackslash(extractfilepath(application.ExeName));
  pinger_complete:= true;
  top_comp:= 8;
  get_computers;
  statusbar1.Panels[1].Text := 'In Progress...     ';
  timer1.Enabled:= true;
end;




procedure Tmainform.FormDestroy(Sender: TObject);
begin
  MySQL55Connection1.Connected:= false;
  SQLTransaction1.Active:= false;
   SQLQuery1.Close;
   SQLTransaction1.EndTransaction;
   SQLTransaction1.CloseDataSets;

   timer1.Enabled:= false;

end;

procedure Tmainform.Vnc_open(Sender: TObject);
var
  Vnc: TProcess;
begin
  Vnc := TProcess.Create(nil);

   // Сообщим Vnc сомандную строку для запуска
   // Let's use the FreePascal compiler
      Vnc.CommandLine := pathexe+'VncViewer.exe '+TLabel(sender).Hint+' /password 123321 /256colors';
  {$ifdef unix}
   Vnc.CommandLine := 'wine '+ pathexe+'VncViewer.exe '+TLabel(sender).Hint+' /password 123321 /256colors';
   {$endif}

   // Необходимо описать опции программы для запуска
   // Эта опция не позволит нашей программе выполнятся до тех пор, пока
   // запущенная программа не закончится
   Vnc.Options := Vnc.Options + [poWaitOnExit];

   // Теперь Vnc знает командную строку
   // и мы ее запускаем
   Vnc.Execute;

   // Пока vnc не прекратит работу, мы досюда не дойдем
   Vnc.Free;
end;

end.

