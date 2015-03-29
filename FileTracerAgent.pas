// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

unit
  FileTracerAgent;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

interface

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  Classes, Tracer;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TFileTracerAgent = class(TInterfacedObject, ITracerAgent)
    private
      FileName: String;
    public
      constructor Create(FileName: String);
      procedure   RenderTrace(Time: Double; Priority: TracePriority; Message: String);
      procedure   CloseTrace();
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

implementation

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  SysUtils, Windows;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TFileTracerAgent.Create(FileName: String);
begin
  Self.FileName := FileName;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TFileTracerAgent.RenderTrace(Time: Double; Priority: TracePriority; Message: String);
var
  Handle: THandle; Line: String; Written: Cardinal;
begin
  // Prepare the message in advance
  Line := FormatDateTime('yyyy-MM-dd HH":"mm":"ss.zzz', Time) + ' ' + Message + #13#10;

  // Append the message to the specified file on disk
  Handle := CreateFile(PChar(Self.FileName), GENERIC_WRITE, FILE_SHARE_READ, nil, OPEN_ALWAYS, FILE_ATTRIBUTE_ARCHIVE, 0); if (Handle <> INVALID_HANDLE_VALUE) then begin
    SetFilePointer(Handle, 0, nil, FILE_END); WriteFile(Handle, Line[1], Length(Line), Written, nil); CloseHandle(Handle);
  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TFileTracerAgent.CloseTrace();
begin
  // Nothing to do
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.