// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

unit
  DnsForwarder;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

interface

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  Classes,
  SysUtils,
  CommunicationChannels,
  Configuration;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TDnsForwarder = class
    public
      class function ForwardDnsRequestForIPv4Udp(ServerCommunicationChannel: TIPv4UdpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word): Boolean;
      class function ForwardDnsRequestForIPv4Tcp(ServerCommunicationChannel: TIPv4TcpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word): Boolean;
      class function ForwardDnsRequestForIPv6Udp(ServerCommunicationChannel: TIPv6UdpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word): Boolean;
      class function ForwardDnsRequestForIPv6Tcp(ServerCommunicationChannel: TIPv6TcpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word): Boolean;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv4UdpIPv4UdpDnsForwarder = class(TThread)
    private
      ServerCommunicationChannel: TIPv4UdpCommunicationChannel;
      ReferenceTime: TDateTime;
      DnsServerIndex: Integer;
      DnsServerConfiguration: TDnsServerConfiguration;
      Buffer: Pointer;
      BufferLen: Integer;
      SessionId: Word;
    public
      constructor Create(ServerCommunicationChannel: TIPv4UdpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);
      procedure   Execute; override;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv4UdpIPv6UdpDnsForwarder = class(TThread)
    private
      ServerCommunicationChannel: TIPv4UdpCommunicationChannel;
      ReferenceTime: TDateTime;
      DnsServerIndex: Integer;
      DnsServerConfiguration: TDnsServerConfiguration;
      Buffer: Pointer;
      BufferLen: Integer;
      SessionId: Word;
    public
      constructor Create(ServerCommunicationChannel: TIPv4UdpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);
      procedure   Execute; override;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv6UdpIPv4UdpDnsForwarder = class(TThread)
    private
      ServerCommunicationChannel: TIPv6UdpCommunicationChannel;
      ReferenceTime: TDateTime;
      DnsServerIndex: Integer;
      DnsServerConfiguration: TDnsServerConfiguration;
      Buffer: Pointer;
      BufferLen: Integer;
      SessionId: Word;
    public
      constructor Create(ServerCommunicationChannel: TIPv6UdpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);
      procedure   Execute; override;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv6UdpIPv6UdpDnsForwarder = class(TThread)
    private
      ServerCommunicationChannel: TIPv6UdpCommunicationChannel;
      ReferenceTime: TDateTime;
      DnsServerIndex: Integer;
      DnsServerConfiguration: TDnsServerConfiguration;
      Buffer: Pointer;
      BufferLen: Integer;
      SessionId: Word;
    public
      constructor Create(ServerCommunicationChannel: TIPv6UdpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);
      procedure   Execute; override;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv4UdpIPv4TcpDnsForwarder = class(TThread)
    private
      ServerCommunicationChannel: TIPv4UdpCommunicationChannel;
      ReferenceTime: TDateTime;
      DnsServerIndex: Integer;
      DnsServerConfiguration: TDnsServerConfiguration;
      Buffer: Pointer;
      BufferLen: Integer;
      SessionId: Word;
    public
      constructor Create(ServerCommunicationChannel: TIPv4UdpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);
      procedure   Execute; override;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv4UdpIPv6TcpDnsForwarder = class(TThread)
    private
      ServerCommunicationChannel: TIPv4UdpCommunicationChannel;
      ReferenceTime: TDateTime;
      DnsServerIndex: Integer;
      DnsServerConfiguration: TDnsServerConfiguration;
      Buffer: Pointer;
      BufferLen: Integer;
      SessionId: Word;
    public
      constructor Create(ServerCommunicationChannel: TIPv4UdpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);
      procedure   Execute; override;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv6UdpIPv4TcpDnsForwarder = class(TThread)
    private
      ServerCommunicationChannel: TIPv6UdpCommunicationChannel;
      ReferenceTime: TDateTime;
      DnsServerIndex: Integer;
      DnsServerConfiguration: TDnsServerConfiguration;
      Buffer: Pointer;
      BufferLen: Integer;
      SessionId: Word;
    public
      constructor Create(ServerCommunicationChannel: TIPv6UdpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);
      procedure   Execute; override;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv6UdpIPv6TcpDnsForwarder = class(TThread)
    private
      ServerCommunicationChannel: TIPv6UdpCommunicationChannel;
      ReferenceTime: TDateTime;
      DnsServerIndex: Integer;
      DnsServerConfiguration: TDnsServerConfiguration;
      Buffer: Pointer;
      BufferLen: Integer;
      SessionId: Word;
    public
      constructor Create(ServerCommunicationChannel: TIPv6UdpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);
      procedure   Execute; override;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv4TcpIPv4TcpDnsForwarder = class(TThread)
    private
      ServerCommunicationChannel: TIPv4TcpCommunicationChannel;
      ReferenceTime: TDateTime;
      DnsServerIndex: Integer;
      DnsServerConfiguration: TDnsServerConfiguration;
      Buffer: Pointer;
      BufferLen: Integer;
      SessionId: Word;
    public
      constructor Create(ServerCommunicationChannel: TIPv4TcpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);
      procedure   Execute; override;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv4TcpIPv6TcpDnsForwarder = class(TThread)
    private
      ServerCommunicationChannel: TIPv4TcpCommunicationChannel;
      ReferenceTime: TDateTime;
      DnsServerIndex: Integer;
      DnsServerConfiguration: TDnsServerConfiguration;
      Buffer: Pointer;
      BufferLen: Integer;
      SessionId: Word;
    public
      constructor Create(ServerCommunicationChannel: TIPv4TcpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);
      procedure   Execute; override;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv6TcpIPv4TcpDnsForwarder = class(TThread)
    private
      ServerCommunicationChannel: TIPv6TcpCommunicationChannel;
      ReferenceTime: TDateTime;
      DnsServerIndex: Integer;
      DnsServerConfiguration: TDnsServerConfiguration;
      Buffer: Pointer;
      BufferLen: Integer;
      SessionId: Word;
    public
      constructor Create(ServerCommunicationChannel: TIPv6TcpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);
      procedure   Execute; override;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv6TcpIPv6TcpDnsForwarder = class(TThread)
    private
      ServerCommunicationChannel: TIPv6TcpCommunicationChannel;
      ReferenceTime: TDateTime;
      DnsServerIndex: Integer;
      DnsServerConfiguration: TDnsServerConfiguration;
      Buffer: Pointer;
      BufferLen: Integer;
      SessionId: Word;
    public
      constructor Create(ServerCommunicationChannel: TIPv6TcpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);
      procedure   Execute; override;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv4UdpIPv4Socks5DnsForwarder = class(TThread)
    private
      ServerCommunicationChannel: TIPv4UdpCommunicationChannel;
      ReferenceTime: TDateTime;
      DnsServerIndex: Integer;
      DnsServerConfiguration: TDnsServerConfiguration;
      Buffer: Pointer;
      BufferLen: Integer;
      SessionId: Word;
    public
      constructor Create(ServerCommunicationChannel: TIPv4UdpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);
      procedure   Execute; override;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv4UdpIPv6Socks5DnsForwarder = class(TThread)
    private
      ServerCommunicationChannel: TIPv4UdpCommunicationChannel;
      ReferenceTime: TDateTime;
      DnsServerIndex: Integer;
      DnsServerConfiguration: TDnsServerConfiguration;
      Buffer: Pointer;
      BufferLen: Integer;
      SessionId: Word;
    public
      constructor Create(ServerCommunicationChannel: TIPv4UdpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);
      procedure   Execute; override;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv6UdpIPv4Socks5DnsForwarder = class(TThread)
    private
      ServerCommunicationChannel: TIPv6UdpCommunicationChannel;
      ReferenceTime: TDateTime;
      DnsServerIndex: Integer;
      DnsServerConfiguration: TDnsServerConfiguration;
      Buffer: Pointer;
      BufferLen: Integer;
      SessionId: Word;
    public
      constructor Create(ServerCommunicationChannel: TIPv6UdpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);
      procedure   Execute; override;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv6UdpIPv6Socks5DnsForwarder = class(TThread)
    private
      ServerCommunicationChannel: TIPv6UdpCommunicationChannel;
      ReferenceTime: TDateTime;
      DnsServerIndex: Integer;
      DnsServerConfiguration: TDnsServerConfiguration;
      Buffer: Pointer;
      BufferLen: Integer;
      SessionId: Word;
    public
      constructor Create(ServerCommunicationChannel: TIPv6UdpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);
      procedure   Execute; override;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv4TcpIPv4Socks5DnsForwarder = class(TThread)
    private
      ServerCommunicationChannel: TIPv4TcpCommunicationChannel;
      ReferenceTime: TDateTime;
      DnsServerIndex: Integer;
      DnsServerConfiguration: TDnsServerConfiguration;
      Buffer: Pointer;
      BufferLen: Integer;
      SessionId: Word;
    public
      constructor Create(ServerCommunicationChannel: TIPv4TcpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);
      procedure   Execute; override;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv4TcpIPv6Socks5DnsForwarder = class(TThread)
    private
      ServerCommunicationChannel: TIPv4TcpCommunicationChannel;
      ReferenceTime: TDateTime;
      DnsServerIndex: Integer;
      DnsServerConfiguration: TDnsServerConfiguration;
      Buffer: Pointer;
      BufferLen: Integer;
      SessionId: Word;
    public
      constructor Create(ServerCommunicationChannel: TIPv4TcpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);
      procedure   Execute; override;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv6TcpIPv4Socks5DnsForwarder = class(TThread)
    private
      ServerCommunicationChannel: TIPv6TcpCommunicationChannel;
      ReferenceTime: TDateTime;
      DnsServerIndex: Integer;
      DnsServerConfiguration: TDnsServerConfiguration;
      Buffer: Pointer;
      BufferLen: Integer;
      SessionId: Word;
    public
      constructor Create(ServerCommunicationChannel: TIPv6TcpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);
      procedure   Execute; override;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv6TcpIPv6Socks5DnsForwarder = class(TThread)
    private
      ServerCommunicationChannel: TIPv6TcpCommunicationChannel;
      ReferenceTime: TDateTime;
      DnsServerIndex: Integer;
      DnsServerConfiguration: TDnsServerConfiguration;
      Buffer: Pointer;
      BufferLen: Integer;
      SessionId: Word;
    public
      constructor Create(ServerCommunicationChannel: TIPv6TcpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);
      procedure   Execute; override;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv4UdpDnsOverHttpsDnsForwarder = class(TThread)
    private
      ServerCommunicationChannel: TIPv4UdpCommunicationChannel;
      ReferenceTime: TDateTime;
      DnsServerIndex: Integer;
      DnsServerConfiguration: TDnsServerConfiguration;
      Buffer: Pointer;
      BufferLen: Integer;
      SessionId: Word;
    public
      constructor Create(ServerCommunicationChannel: TIPv4UdpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);
      procedure   Execute; override;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv6UdpDnsOverHttpsDnsForwarder = class(TThread)
    private
      ServerCommunicationChannel: TIPv6UdpCommunicationChannel;
      ReferenceTime: TDateTime;
      DnsServerIndex: Integer;
      DnsServerConfiguration: TDnsServerConfiguration;
      Buffer: Pointer;
      BufferLen: Integer;
      SessionId: Word;
    public
      constructor Create(ServerCommunicationChannel: TIPv6UdpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);
      procedure   Execute; override;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv4TcpDnsOverHttpsDnsForwarder = class(TThread)
    private
      ServerCommunicationChannel: TIPv4TcpCommunicationChannel;
      ReferenceTime: TDateTime;
      DnsServerIndex: Integer;
      DnsServerConfiguration: TDnsServerConfiguration;
      Buffer: Pointer;
      BufferLen: Integer;
      SessionId: Word;
    public
      constructor Create(ServerCommunicationChannel: TIPv4TcpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);
      procedure   Execute; override;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv6TcpDnsOverHttpsDnsForwarder = class(TThread)
    private
      ServerCommunicationChannel: TIPv6TcpCommunicationChannel;
      ReferenceTime: TDateTime;
      DnsServerIndex: Integer;
      DnsServerConfiguration: TDnsServerConfiguration;
      Buffer: Pointer;
      BufferLen: Integer;
      SessionId: Word;
    public
      constructor Create(ServerCommunicationChannel: TIPv6TcpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);
      procedure   Execute; override;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

implementation

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  Windows,
  DnsProtocol,
  DnsResolver,
  IPUtils,
  MemoryManager,
  Tracer;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  TF: Int64;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TDnsForwarder.ForwardDnsRequestForIPv4Udp(ServerCommunicationChannel: TIPv4UdpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word): Boolean;

var
  DnsForwarder: TThread;

begin

  Result := False;

  DnsForwarder := nil; try

    case DnsServerConfiguration.Protocol of

      UdpProtocol:

        if DnsServerConfiguration.Address.IsIPv6Address then begin

          DnsForwarder := TIPv4UdpIPv6UdpDnsForwarder.Create(ServerCommunicationChannel, ReferenceTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, SessionId);

          if (DnsForwarder <> nil) then begin

            DnsForwarder.Resume;

            Result := True;

          end;

        end else begin

          DnsForwarder := TIPv4UdpIPv4UdpDnsForwarder.Create(ServerCommunicationChannel, ReferenceTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, SessionId);

          if (DnsForwarder <> nil) then begin

            DnsForwarder.Resume;

            Result := True;

          end;

        end;

      TcpProtocol:

        if DnsServerConfiguration.Address.IsIPv6Address then begin

          DnsForwarder := TIPv4UdpIPv6TcpDnsForwarder.Create(ServerCommunicationChannel, ReferenceTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, SessionId);

          if (DnsForwarder <> nil) then begin

            DnsForwarder.Resume;

            Result := True;

          end;

        end else begin

          DnsForwarder := TIPv4UdpIPv4TcpDnsForwarder.Create(ServerCommunicationChannel, ReferenceTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, SessionId);

          if (DnsForwarder <> nil) then begin

            DnsForwarder.Resume;

            Result := True;

          end;

        end;

      Socks5Protocol:

        if DnsServerConfiguration.Socks5ProtocolProxyAddress.IsIPv6Address then begin

          DnsForwarder := TIPv4UdpIPv6Socks5DnsForwarder.Create(ServerCommunicationChannel, ReferenceTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, SessionId);

          if (DnsForwarder <> nil) then begin

            DnsForwarder.Resume;

            Result := True;

          end;

        end else begin

          DnsForwarder := TIPv4UdpIPv4Socks5DnsForwarder.Create(ServerCommunicationChannel, ReferenceTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, SessionId);

          if (DnsForwarder <> nil) then begin

            DnsForwarder.Resume;

            Result := True;

          end;

        end;

      DnsOverHttpsProtocol:

        begin

          DnsForwarder := TIPv4UdpDnsOverHttpsDnsForwarder.Create(ServerCommunicationChannel, ReferenceTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, SessionId);

          if (DnsForwarder <> nil) then begin

            DnsForwarder.Resume;

            Result := True;

          end;

        end;

    end;

  except

    on E: Exception do if (DnsForwarder <> nil) then DnsForwarder.Destroy;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TDnsForwarder.ForwardDnsRequestForIPv4Tcp(ServerCommunicationChannel: TIPv4TcpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word): Boolean;

var
  DnsForwarder: TThread;

begin

  Result := False;

  DnsForwarder := nil; try

    case DnsServerConfiguration.Protocol of

      UdpProtocol: // TCP > UDP is not a good idea, therefore...

        if DnsServerConfiguration.Address.IsIPv6Address then begin

          DnsForwarder := TIPv4TcpIPv6TcpDnsForwarder.Create(ServerCommunicationChannel, ReferenceTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, SessionId);

          if (DnsForwarder <> nil) then begin

            DnsForwarder.Resume;

            Result := True;

          end;

        end else begin

          DnsForwarder := TIPv4TcpIPv4TcpDnsForwarder.Create(ServerCommunicationChannel, ReferenceTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, SessionId);

          if (DnsForwarder <> nil) then begin

            DnsForwarder.Resume;

            Result := True;

          end;

        end;

      TcpProtocol:

        if DnsServerConfiguration.Address.IsIPv6Address then begin

          DnsForwarder := TIPv4TcpIPv6TcpDnsForwarder.Create(ServerCommunicationChannel, ReferenceTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, SessionId);

          if (DnsForwarder <> nil) then begin

            DnsForwarder.Resume;

            Result := True;

          end;

        end else begin

          DnsForwarder := TIPv4TcpIPv4TcpDnsForwarder.Create(ServerCommunicationChannel, ReferenceTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, SessionId);

          if (DnsForwarder <> nil) then begin

            DnsForwarder.Resume;

            Result := True;

          end;

        end;

      Socks5Protocol:

        if DnsServerConfiguration.Socks5ProtocolProxyAddress.IsIPv6Address then begin

          DnsForwarder := TIPv4TcpIPv6Socks5DnsForwarder.Create(ServerCommunicationChannel, ReferenceTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, SessionId);

          if (DnsForwarder <> nil) then begin

            DnsForwarder.Resume;

            Result := True;

          end;

        end else begin

          DnsForwarder := TIPv4TcpIPv4Socks5DnsForwarder.Create(ServerCommunicationChannel, ReferenceTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, SessionId);

          if (DnsForwarder <> nil) then begin

            DnsForwarder.Resume;

            Result := True;

          end;

        end;

      DnsOverHttpsProtocol:

        begin

          DnsForwarder := TIPv4TcpDnsOverHttpsDnsForwarder.Create(ServerCommunicationChannel, ReferenceTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, SessionId);

          if (DnsForwarder <> nil) then begin

            DnsForwarder.Resume;

            Result := True;

          end;

        end;

    end;

  except

    on E: Exception do if (DnsForwarder <> nil) then DnsForwarder.Destroy;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TDnsForwarder.ForwardDnsRequestForIPv6Udp(ServerCommunicationChannel: TIPv6UdpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word): Boolean;

var
  DnsForwarder: TThread;

begin

  Result := False;

  DnsForwarder := nil; try

    case DnsServerConfiguration.Protocol of

      UdpProtocol:

        if DnsServerConfiguration.Address.IsIPv6Address then begin

          DnsForwarder := TIPv6UdpIPv6UdpDnsForwarder.Create(ServerCommunicationChannel, ReferenceTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, SessionId);

          if (DnsForwarder <> nil) then begin

            DnsForwarder.Resume;

            Result := True;

          end;

        end else begin

          DnsForwarder := TIPv6UdpIPv4UdpDnsForwarder.Create(ServerCommunicationChannel, ReferenceTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, SessionId);

          if (DnsForwarder <> nil) then begin

            DnsForwarder.Resume;

            Result := True;

          end;

        end;

      TcpProtocol:

        if DnsServerConfiguration.Address.IsIPv6Address then begin

          DnsForwarder := TIPv6UdpIPv6TcpDnsForwarder.Create(ServerCommunicationChannel, ReferenceTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, SessionId);

          if (DnsForwarder <> nil) then begin

            DnsForwarder.Resume;

            Result := True;

          end;

        end else begin

          DnsForwarder := TIPv6UdpIPv4TcpDnsForwarder.Create(ServerCommunicationChannel, ReferenceTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, SessionId);

          if (DnsForwarder <> nil) then begin

            DnsForwarder.Resume;

            Result := True;

          end;

        end;

      Socks5Protocol:

        if DnsServerConfiguration.Socks5ProtocolProxyAddress.IsIPv6Address then begin

          DnsForwarder := TIPv6UdpIPv6Socks5DnsForwarder.Create(ServerCommunicationChannel, ReferenceTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, SessionId);

          if (DnsForwarder <> nil) then begin

            DnsForwarder.Resume;

            Result := True;

          end;

        end else begin

          DnsForwarder := TIPv6UdpIPv4Socks5DnsForwarder.Create(ServerCommunicationChannel, ReferenceTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, SessionId);

          if (DnsForwarder <> nil) then begin

            DnsForwarder.Resume;

            Result := True;

          end;

        end;

      DnsOverHttpsProtocol:

        begin

          DnsForwarder := TIPv6UdpDnsOverHttpsDnsForwarder.Create(ServerCommunicationChannel, ReferenceTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, SessionId);

          if (DnsForwarder <> nil) then begin

            DnsForwarder.Resume;

            Result := True;

          end;

        end;

    end;

  except

    on E: Exception do if (DnsForwarder <> nil) then DnsForwarder.Destroy;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TDnsForwarder.ForwardDnsRequestForIPv6Tcp(ServerCommunicationChannel: TIPv6TcpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word): Boolean;

var
  DnsForwarder: TThread;

begin

  Result := False;

  DnsForwarder := nil; try

    case DnsServerConfiguration.Protocol of

      UdpProtocol: // TCP > UDP is not a good idea, therefore...

        if DnsServerConfiguration.Address.IsIPv6Address then begin

          DnsForwarder := TIPv6TcpIPv6TcpDnsForwarder.Create(ServerCommunicationChannel, ReferenceTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, SessionId);

          if (DnsForwarder <> nil) then begin

            DnsForwarder.Resume;

            Result := True;

          end;

        end else begin

          DnsForwarder := TIPv6TcpIPv4TcpDnsForwarder.Create(ServerCommunicationChannel, ReferenceTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, SessionId);

          if (DnsForwarder <> nil) then begin

            DnsForwarder.Resume;

            Result := True;

          end;

        end;

      TcpProtocol:

        if DnsServerConfiguration.Address.IsIPv6Address then begin

          DnsForwarder := TIPv6TcpIPv6TcpDnsForwarder.Create(ServerCommunicationChannel, ReferenceTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, SessionId);

          if (DnsForwarder <> nil) then begin

            DnsForwarder.Resume;

            Result := True;

          end;

        end else begin

          DnsForwarder := TIPv6TcpIPv4TcpDnsForwarder.Create(ServerCommunicationChannel, ReferenceTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, SessionId);

          if (DnsForwarder <> nil) then begin

            DnsForwarder.Resume;

            Result := True;

          end;

        end;

      Socks5Protocol:

        if DnsServerConfiguration.Socks5ProtocolProxyAddress.IsIPv6Address then begin

          DnsForwarder := TIPv6TcpIPv6Socks5DnsForwarder.Create(ServerCommunicationChannel, ReferenceTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, SessionId);

          if (DnsForwarder <> nil) then begin

            DnsForwarder.Resume;

            Result := True;

          end;

        end else begin

          DnsForwarder := TIPv6TcpIPv4Socks5DnsForwarder.Create(ServerCommunicationChannel, ReferenceTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, SessionId);

          if (DnsForwarder <> nil) then begin

            DnsForwarder.Resume;

            Result := True;

          end;

        end;

      DnsOverHttpsProtocol:

        begin

          DnsForwarder := TIPv6TcpDnsOverHttpsDnsForwarder.Create(ServerCommunicationChannel, ReferenceTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, SessionId);

          if (DnsForwarder <> nil) then begin

            DnsForwarder.Resume;

            Result := True;

          end;

        end;

    end;

  except

    on E: Exception do if (DnsForwarder <> nil) then DnsForwarder.Destroy;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv4UdpIPv4UdpDnsForwarder.Create(ServerCommunicationChannel: TIPv4UdpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);

begin

  inherited Create(True); Self.FreeOnTerminate := True;

  Self.ServerCommunicationChannel := ServerCommunicationChannel; Self.ReferenceTime := ReferenceTime; Self.DnsServerIndex := DnsServerIndex; Self.DnsServerConfiguration := DnsServerConfiguration; Self.Buffer := TMemoryManager.GetMemory(MAX_DNS_BUFFER_LEN); Move(Buffer^, Self.Buffer^, BufferLen); Self.BufferLen := BufferLen; Self.SessionId := SessionId;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv4UdpIPv4UdpDnsForwarder.Execute;

var
  ClientCommunicationChannel: TIPv4UdpCommunicationChannel; T1, T2: Int64; Address: TIPv4Address; Port: Word;

begin

  try

    ClientCommunicationChannel := TIPv4UdpCommunicationChannel.Create;

    try

      QueryPerformanceCounter(T1);

      ClientCommunicationChannel.Bind(ANY_IPV4_ADDRESS);

      ClientCommunicationChannel.Send(Self.Buffer, Self.BufferLen, Self.DnsServerConfiguration.Address.IPv4Address, Self.DnsServerConfiguration.Port);

      if ClientCommunicationChannel.Receive(TConfiguration.GetServerUdpProtocolResponseTimeout, MAX_DNS_BUFFER_LEN, Self.Buffer, Self.BufferLen, Address, Port) then begin

        QueryPerformanceCounter(T2);

        if TIPv4AddressUtility.AreEqual(Address, Self.DnsServerConfiguration.Address.IPv4Address) then begin

          TDnsResolver.HandleDnsResponseForIPv4Udp(Self.ServerCommunicationChannel, Now, Self.Buffer, Self.BufferLen, Self.DnsServerIndex, (T2 - T1) / TF, Self.DnsServerConfiguration);

        end else begin

          if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TIPv4UdpIPv4UdpDnsForwarder.Execute: Unexpected packet received from address ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + ' [' + TDnsProtocolUtility.PrintGenericPacketBytesAsStringFromPacket(Self.Buffer, Self.BufferLen) + '].');

        end;

      end else begin

        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TIPv4UdpIPv4UdpDnsForwarder.Execute: No response received from server while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + '.');

      end;

    finally

      ClientCommunicationChannel.Free;

    end;

  except

    on E: Exception do if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'TIPv4UdpIPv4UdpDnsForwarder.Execute: The following error occurred while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + ': ' + E.Message);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TIPv4UdpIPv4UdpDnsForwarder.Destroy;

begin

  TMemoryManager.FreeMemory(Self.Buffer, MAX_DNS_BUFFER_LEN);

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv4UdpIPv6UdpDnsForwarder.Create(ServerCommunicationChannel: TIPv4UdpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);

begin

  inherited Create(True); Self.FreeOnTerminate := True;

  Self.ServerCommunicationChannel := ServerCommunicationChannel; Self.ReferenceTime := ReferenceTime; Self.DnsServerIndex := DnsServerIndex; Self.DnsServerConfiguration := DnsServerConfiguration; Self.Buffer := TMemoryManager.GetMemory(MAX_DNS_BUFFER_LEN); Move(Buffer^, Self.Buffer^, BufferLen); Self.BufferLen := BufferLen; Self.SessionId := SessionId;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv4UdpIPv6UdpDnsForwarder.Execute;

var
  ClientCommunicationChannel: TIPv6UdpCommunicationChannel; T1, T2: Int64; Address: TIPv6Address; Port: Word;

begin

  try

    ClientCommunicationChannel := TIPv6UdpCommunicationChannel.Create;

    try

      QueryPerformanceCounter(T1);

      ClientCommunicationChannel.Bind(ANY_IPV6_ADDRESS);

      ClientCommunicationChannel.Send(Self.Buffer, Self.BufferLen, Self.DnsServerConfiguration.Address.IPv6Address, Self.DnsServerConfiguration.Port);

      if ClientCommunicationChannel.Receive(TConfiguration.GetServerUdpProtocolResponseTimeout, MAX_DNS_BUFFER_LEN, Self.Buffer, Self.BufferLen, Address, Port) then begin

        QueryPerformanceCounter(T2);

        if TIPv6AddressUtility.AreEqual(Address, Self.DnsServerConfiguration.Address.IPv6Address) then begin

          TDnsResolver.HandleDnsResponseForIPv4Udp(Self.ServerCommunicationChannel, Now, Self.Buffer, Self.BufferLen, Self.DnsServerIndex, (T2 - T1) / TF, Self.DnsServerConfiguration);

        end else begin

          if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TIPv4UdpIPv6UdpDnsForwarder.Execute: Unexpected packet received from address ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + ' [' + TDnsProtocolUtility.PrintGenericPacketBytesAsStringFromPacket(Self.Buffer, Self.BufferLen) + '].');

        end;

      end else begin

        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TIPv4UdpIPv6UdpDnsForwarder.Execute: No response received from server while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + '.');

      end;

    finally

      ClientCommunicationChannel.Free;

    end;

  except

    on E: Exception do if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'TIPv4UdpIPv6UdpDnsForwarder.Execute: The following error occurred while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + ': ' + E.Message);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TIPv4UdpIPv6UdpDnsForwarder.Destroy;

begin

  TMemoryManager.FreeMemory(Self.Buffer, MAX_DNS_BUFFER_LEN);

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv6UdpIPv4UdpDnsForwarder.Create(ServerCommunicationChannel: TIPv6UdpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);

begin

  inherited Create(True); Self.FreeOnTerminate := True;

  Self.ServerCommunicationChannel := ServerCommunicationChannel; Self.ReferenceTime := ReferenceTime; Self.DnsServerIndex := DnsServerIndex; Self.DnsServerConfiguration := DnsServerConfiguration; Self.Buffer := TMemoryManager.GetMemory(MAX_DNS_BUFFER_LEN); Move(Buffer^, Self.Buffer^, BufferLen); Self.BufferLen := BufferLen; Self.SessionId := SessionId;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv6UdpIPv4UdpDnsForwarder.Execute;

var
  ClientCommunicationChannel: TIPv4UdpCommunicationChannel; T1, T2: Int64; Address: TIPv4Address; Port: Word;

begin

  try

    ClientCommunicationChannel := TIPv4UdpCommunicationChannel.Create;

    try

      QueryPerformanceCounter(T1);

      ClientCommunicationChannel.Bind(ANY_IPV4_ADDRESS);

      ClientCommunicationChannel.Send(Self.Buffer, Self.BufferLen, Self.DnsServerConfiguration.Address.IPv4Address, Self.DnsServerConfiguration.Port);

      if ClientCommunicationChannel.Receive(TConfiguration.GetServerUdpProtocolResponseTimeout, MAX_DNS_BUFFER_LEN, Self.Buffer, Self.BufferLen, Address, Port) then begin

        QueryPerformanceCounter(T2);

        if TIPv4AddressUtility.AreEqual(Address, Self.DnsServerConfiguration.Address.IPv4Address) then begin

          TDnsResolver.HandleDnsResponseForIPv6Udp(Self.ServerCommunicationChannel, Now, Self.Buffer, Self.BufferLen, Self.DnsServerIndex, (T2 - T1) / TF, Self.DnsServerConfiguration);

        end else begin

          if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TIPv6UdpIPv4UdpDnsForwarder.Execute: Unexpected packet received from address ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + ' [' + TDnsProtocolUtility.PrintGenericPacketBytesAsStringFromPacket(Self.Buffer, Self.BufferLen) + '].');

        end;

      end else begin

        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TIPv6UdpIPv4UdpDnsForwarder.Execute: No response received from server while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + '.');

      end;

    finally

      ClientCommunicationChannel.Free;

    end;

  except

    on E: Exception do if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'TIPv6UdpIPv4UdpDnsForwarder.Execute: The following error occurred while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + ': ' + E.Message);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TIPv6UdpIPv4UdpDnsForwarder.Destroy;

begin

  TMemoryManager.FreeMemory(Self.Buffer, MAX_DNS_BUFFER_LEN);

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv6UdpIPv6UdpDnsForwarder.Create(ServerCommunicationChannel: TIPv6UdpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);

begin

  inherited Create(True); Self.FreeOnTerminate := True;

  Self.ServerCommunicationChannel := ServerCommunicationChannel; Self.ReferenceTime := ReferenceTime; Self.DnsServerIndex := DnsServerIndex; Self.DnsServerConfiguration := DnsServerConfiguration; Self.Buffer := TMemoryManager.GetMemory(MAX_DNS_BUFFER_LEN); Move(Buffer^, Self.Buffer^, BufferLen); Self.BufferLen := BufferLen; Self.SessionId := SessionId;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv6UdpIPv6UdpDnsForwarder.Execute;

var
  ClientCommunicationChannel: TIPv6UdpCommunicationChannel; T1, T2: Int64; Address: TIPv6Address; Port: Word;

begin

  try

    ClientCommunicationChannel := TIPv6UdpCommunicationChannel.Create;

    try

      QueryPerformanceCounter(T1);

      ClientCommunicationChannel.Bind(ANY_IPV6_ADDRESS);

      ClientCommunicationChannel.Send(Self.Buffer, Self.BufferLen, Self.DnsServerConfiguration.Address.IPv6Address, Self.DnsServerConfiguration.Port);

      if ClientCommunicationChannel.Receive(TConfiguration.GetServerUdpProtocolResponseTimeout, MAX_DNS_BUFFER_LEN, Self.Buffer, Self.BufferLen, Address, Port) then begin

        QueryPerformanceCounter(T2);

        if TIPv6AddressUtility.AreEqual(Address, Self.DnsServerConfiguration.Address.IPv6Address) then begin

          TDnsResolver.HandleDnsResponseForIPv6Udp(Self.ServerCommunicationChannel, Now, Self.Buffer, Self.BufferLen, Self.DnsServerIndex, (T2 - T1) / TF, Self.DnsServerConfiguration);

        end else begin

          if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TIPv6UdpIPv6UdpDnsForwarder.Execute: Unexpected packet received from address ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + ' [' + TDnsProtocolUtility.PrintGenericPacketBytesAsStringFromPacket(Self.Buffer, Self.BufferLen) + '].');

        end;

      end else begin

        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TIPv6UdpIPv6UdpDnsForwarder.Execute: No response received from server while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + '.');

      end;

    finally

      ClientCommunicationChannel.Free;

    end;

  except

    on E: Exception do if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'TIPv6UdpIPv6UdpDnsForwarder.Execute: The following error occurred while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + ': ' + E.Message);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TIPv6UdpIPv6UdpDnsForwarder.Destroy;

begin

  TMemoryManager.FreeMemory(Self.Buffer, MAX_DNS_BUFFER_LEN);

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv4UdpIPv4TcpDnsForwarder.Create(ServerCommunicationChannel: TIPv4UdpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);

begin

  inherited Create(True); Self.FreeOnTerminate := True;

  Self.ServerCommunicationChannel := ServerCommunicationChannel; Self.ReferenceTime := ReferenceTime; Self.DnsServerIndex := DnsServerIndex; Self.DnsServerConfiguration := DnsServerConfiguration; Self.Buffer := TMemoryManager.GetMemory(MAX_DNS_BUFFER_LEN); Move(Buffer^, Self.Buffer^, BufferLen); Self.BufferLen := BufferLen; Self.SessionId := SessionId;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv4UdpIPv4TcpDnsForwarder.Execute;

var
  ClientCommunicationChannel: TIPv4TcpCommunicationChannel; T1, T2: Int64;

begin

  try

    ClientCommunicationChannel := TIPv4TcpCommunicationChannel.Create;

    try

      QueryPerformanceCounter(T1);

      ClientCommunicationChannel.Connect(Self.DnsServerConfiguration.Address.IPv4Address, Self.DnsServerConfiguration.Port);

      ClientCommunicationChannel.Send(Self.Buffer, Self.BufferLen);

      if ClientCommunicationChannel.Receive(TConfiguration.GetServerTcpProtocolResponseTimeout, TConfiguration.GetServerTcpProtocolInternalTimeout, MAX_DNS_BUFFER_LEN, Self.Buffer, Self.BufferLen) then begin

        QueryPerformanceCounter(T2);

        TDnsResolver.HandleDnsResponseForIPv4Udp(Self.ServerCommunicationChannel, Now, Self.Buffer, Self.BufferLen, Self.DnsServerIndex, (T2 - T1) / TF, Self.DnsServerConfiguration);

      end else begin

        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TIPv4UdpIPv4TcpDnsForwarder.Execute: No response received from server while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + '.');

      end;

    finally

      ClientCommunicationChannel.Free;

    end;

  except

    on E: Exception do if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'TIPv4UdpIPv4TcpDnsForwarder.Execute: The following error occurred while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + ': ' + E.Message);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TIPv4UdpIPv4TcpDnsForwarder.Destroy;

begin

  TMemoryManager.FreeMemory(Self.Buffer, MAX_DNS_BUFFER_LEN);

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv4UdpIPv6TcpDnsForwarder.Create(ServerCommunicationChannel: TIPv4UdpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);

begin

  inherited Create(True); Self.FreeOnTerminate := True;

  Self.ServerCommunicationChannel := ServerCommunicationChannel; Self.ReferenceTime := ReferenceTime; Self.DnsServerIndex := DnsServerIndex; Self.DnsServerConfiguration := DnsServerConfiguration; Self.Buffer := TMemoryManager.GetMemory(MAX_DNS_BUFFER_LEN); Move(Buffer^, Self.Buffer^, BufferLen); Self.BufferLen := BufferLen; Self.SessionId := SessionId;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv4UdpIPv6TcpDnsForwarder.Execute;

var
  ClientCommunicationChannel: TIPv6TcpCommunicationChannel; T1, T2: Int64;

begin

  try

    ClientCommunicationChannel := TIPv6TcpCommunicationChannel.Create;

    try

      QueryPerformanceCounter(T1);

      ClientCommunicationChannel.Connect(Self.DnsServerConfiguration.Address.IPv6Address, Self.DnsServerConfiguration.Port);

      ClientCommunicationChannel.Send(Self.Buffer, Self.BufferLen);

      if ClientCommunicationChannel.Receive(TConfiguration.GetServerTcpProtocolResponseTimeout, TConfiguration.GetServerTcpProtocolInternalTimeout, MAX_DNS_BUFFER_LEN, Self.Buffer, Self.BufferLen) then begin

        QueryPerformanceCounter(T2);

        TDnsResolver.HandleDnsResponseForIPv4Udp(Self.ServerCommunicationChannel, Now, Self.Buffer, Self.BufferLen, Self.DnsServerIndex, (T2 - T1) / TF, Self.DnsServerConfiguration);

      end else begin

        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TIPv4UdpIPv6TcpDnsForwarder.Execute: No response received from server while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + '.');

      end;

    finally

      ClientCommunicationChannel.Free;

    end;

  except

    on E: Exception do if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'TIPv4UdpIPv6TcpDnsForwarder.Execute: The following error occurred while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + ': ' + E.Message);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TIPv4UdpIPv6TcpDnsForwarder.Destroy;

begin

  TMemoryManager.FreeMemory(Self.Buffer, MAX_DNS_BUFFER_LEN);

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv6UdpIPv4TcpDnsForwarder.Create(ServerCommunicationChannel: TIPv6UdpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);

begin

  inherited Create(True); Self.FreeOnTerminate := True;

  Self.ServerCommunicationChannel := ServerCommunicationChannel; Self.ReferenceTime := ReferenceTime; Self.DnsServerIndex := DnsServerIndex; Self.DnsServerConfiguration := DnsServerConfiguration; Self.Buffer := TMemoryManager.GetMemory(MAX_DNS_BUFFER_LEN); Move(Buffer^, Self.Buffer^, BufferLen); Self.BufferLen := BufferLen; Self.SessionId := SessionId;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv6UdpIPv4TcpDnsForwarder.Execute;

var
  ClientCommunicationChannel: TIPv4TcpCommunicationChannel; T1, T2: Int64;

begin

  try

    ClientCommunicationChannel := TIPv4TcpCommunicationChannel.Create;

    try

      QueryPerformanceCounter(T1);

      ClientCommunicationChannel.Connect(Self.DnsServerConfiguration.Address.IPv4Address, Self.DnsServerConfiguration.Port);

      ClientCommunicationChannel.Send(Self.Buffer, Self.BufferLen);

      if ClientCommunicationChannel.Receive(TConfiguration.GetServerTcpProtocolResponseTimeout, TConfiguration.GetServerTcpProtocolInternalTimeout, MAX_DNS_BUFFER_LEN, Self.Buffer, Self.BufferLen) then begin

        QueryPerformanceCounter(T2);

        TDnsResolver.HandleDnsResponseForIPv6Udp(Self.ServerCommunicationChannel, Now, Self.Buffer, Self.BufferLen, Self.DnsServerIndex, (T2 - T1) / TF, Self.DnsServerConfiguration);

      end else begin

        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TIPv6UdpIPv4TcpDnsForwarder.Execute: No response received from server while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + '.');

      end;

    finally

      ClientCommunicationChannel.Free;

    end;

  except

    on E: Exception do if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'TIPv6UdpIPv4TcpDnsForwarder.Execute: The following error occurred while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + ': ' + E.Message);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TIPv6UdpIPv4TcpDnsForwarder.Destroy;

begin

  TMemoryManager.FreeMemory(Self.Buffer, MAX_DNS_BUFFER_LEN);

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv6UdpIPv6TcpDnsForwarder.Create(ServerCommunicationChannel: TIPv6UdpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);

begin

  inherited Create(True); Self.FreeOnTerminate := True;

  Self.ServerCommunicationChannel := ServerCommunicationChannel; Self.ReferenceTime := ReferenceTime; Self.DnsServerIndex := DnsServerIndex; Self.DnsServerConfiguration := DnsServerConfiguration; Self.Buffer := TMemoryManager.GetMemory(MAX_DNS_BUFFER_LEN); Move(Buffer^, Self.Buffer^, BufferLen); Self.BufferLen := BufferLen; Self.SessionId := SessionId;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv6UdpIPv6TcpDnsForwarder.Execute;

var
  ClientCommunicationChannel: TIPv6TcpCommunicationChannel; T1, T2: Int64;

begin

  try

    ClientCommunicationChannel := TIPv6TcpCommunicationChannel.Create;

    try

      QueryPerformanceCounter(T1);

      ClientCommunicationChannel.Connect(Self.DnsServerConfiguration.Address.IPv6Address, Self.DnsServerConfiguration.Port);

      ClientCommunicationChannel.Send(Self.Buffer, Self.BufferLen);

      if ClientCommunicationChannel.Receive(TConfiguration.GetServerTcpProtocolResponseTimeout, TConfiguration.GetServerTcpProtocolInternalTimeout, MAX_DNS_BUFFER_LEN, Self.Buffer, Self.BufferLen) then begin

        QueryPerformanceCounter(T2);

        TDnsResolver.HandleDnsResponseForIPv6Udp(Self.ServerCommunicationChannel, Now, Self.Buffer, Self.BufferLen, Self.DnsServerIndex, (T2 - T1) / TF, Self.DnsServerConfiguration);

      end else begin

        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TIPv6UdpIPv6TcpDnsForwarder.Execute: No response received from server while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + '.');

      end;

    finally

      ClientCommunicationChannel.Free;

    end;

  except

    on E: Exception do if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'TIPv6UdpIPv6TcpDnsForwarder.Execute: The following error occurred while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + ': ' + E.Message);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TIPv6UdpIPv6TcpDnsForwarder.Destroy;

begin

  TMemoryManager.FreeMemory(Self.Buffer, MAX_DNS_BUFFER_LEN);

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv4TcpIPv4TcpDnsForwarder.Create(ServerCommunicationChannel: TIPv4TcpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);

begin

  inherited Create(True); Self.FreeOnTerminate := True;

  Self.ServerCommunicationChannel := ServerCommunicationChannel; Self.ReferenceTime := ReferenceTime; Self.DnsServerIndex := DnsServerIndex; Self.DnsServerConfiguration := DnsServerConfiguration; Self.Buffer := TMemoryManager.GetMemory(MAX_DNS_BUFFER_LEN); Move(Buffer^, Self.Buffer^, BufferLen); Self.BufferLen := BufferLen; Self.SessionId := SessionId;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv4TcpIPv4TcpDnsForwarder.Execute;

var
  ClientCommunicationChannel: TIPv4TcpCommunicationChannel; T1, T2: Int64;

begin

  try

    ClientCommunicationChannel := TIPv4TcpCommunicationChannel.Create;

    try

      QueryPerformanceCounter(T1);

      ClientCommunicationChannel.Connect(Self.DnsServerConfiguration.Address.IPv4Address, Self.DnsServerConfiguration.Port);

      ClientCommunicationChannel.Send(Self.Buffer, Self.BufferLen);

      if ClientCommunicationChannel.Receive(TConfiguration.GetServerTcpProtocolResponseTimeout, TConfiguration.GetServerTcpProtocolInternalTimeout, MAX_DNS_BUFFER_LEN, Self.Buffer, Self.BufferLen) then begin

        QueryPerformanceCounter(T2);

        TDnsResolver.HandleDnsResponseForIPv4Tcp(Self.ServerCommunicationChannel, Now, Self.Buffer, Self.BufferLen, Self.DnsServerIndex, (T2 - T1) / TF, Self.DnsServerConfiguration);

      end else begin

        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TIPv4TcpIPv4TcpDnsForwarder.Execute: No response received from server while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + '.');

      end;

    finally

      ClientCommunicationChannel.Free;

    end;

  except

    on E: Exception do if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'TIPv4TcpIPv4TcpDnsForwarder.Execute: The following error occurred while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + ': ' + E.Message);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TIPv4TcpIPv4TcpDnsForwarder.Destroy;

begin

  TMemoryManager.FreeMemory(Self.Buffer, MAX_DNS_BUFFER_LEN);

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv4TcpIPv6TcpDnsForwarder.Create(ServerCommunicationChannel: TIPv4TcpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);

begin

  inherited Create(True); Self.FreeOnTerminate := True;

  Self.ServerCommunicationChannel := ServerCommunicationChannel; Self.ReferenceTime := ReferenceTime; Self.DnsServerIndex := DnsServerIndex; Self.DnsServerConfiguration := DnsServerConfiguration; Self.Buffer := TMemoryManager.GetMemory(MAX_DNS_BUFFER_LEN); Move(Buffer^, Self.Buffer^, BufferLen); Self.BufferLen := BufferLen; Self.SessionId := SessionId;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv4TcpIPv6TcpDnsForwarder.Execute;

var
  ClientCommunicationChannel: TIPv6TcpCommunicationChannel; T1, T2: Int64;

begin

  try

    ClientCommunicationChannel := TIPv6TcpCommunicationChannel.Create;

    try

      QueryPerformanceCounter(T1);

      ClientCommunicationChannel.Connect(Self.DnsServerConfiguration.Address.IPv6Address, Self.DnsServerConfiguration.Port);

      ClientCommunicationChannel.Send(Self.Buffer, Self.BufferLen);

      if ClientCommunicationChannel.Receive(TConfiguration.GetServerTcpProtocolResponseTimeout, TConfiguration.GetServerTcpProtocolInternalTimeout, MAX_DNS_BUFFER_LEN, Self.Buffer, Self.BufferLen) then begin

        QueryPerformanceCounter(T2);

        TDnsResolver.HandleDnsResponseForIPv4Tcp(Self.ServerCommunicationChannel, Now, Self.Buffer, Self.BufferLen, Self.DnsServerIndex, (T2 - T1) / TF, Self.DnsServerConfiguration);

      end else begin

        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TIPv4TcpIPv6TcpDnsForwarder.Execute: No response received from server while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + '.');

      end;

    finally

      ClientCommunicationChannel.Free;

    end;

  except

    on E: Exception do if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'TIPv4TcpIPv6TcpDnsForwarder.Execute: The following error occurred while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + ': ' + E.Message);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TIPv4TcpIPv6TcpDnsForwarder.Destroy;

begin

  TMemoryManager.FreeMemory(Self.Buffer, MAX_DNS_BUFFER_LEN);

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv6TcpIPv4TcpDnsForwarder.Create(ServerCommunicationChannel: TIPv6TcpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);

begin

  inherited Create(True); Self.FreeOnTerminate := True;

  Self.ServerCommunicationChannel := ServerCommunicationChannel; Self.ReferenceTime := ReferenceTime; Self.DnsServerIndex := DnsServerIndex; Self.DnsServerConfiguration := DnsServerConfiguration; Self.Buffer := TMemoryManager.GetMemory(MAX_DNS_BUFFER_LEN); Move(Buffer^, Self.Buffer^, BufferLen); Self.BufferLen := BufferLen; Self.SessionId := SessionId;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv6TcpIPv4TcpDnsForwarder.Execute;

var
  ClientCommunicationChannel: TIPv4TcpCommunicationChannel; T1, T2: Int64;

begin

  try

    ClientCommunicationChannel := TIPv4TcpCommunicationChannel.Create;

    try

      QueryPerformanceCounter(T1);

      ClientCommunicationChannel.Connect(Self.DnsServerConfiguration.Address.IPv4Address, Self.DnsServerConfiguration.Port);

      ClientCommunicationChannel.Send(Self.Buffer, Self.BufferLen);

      if ClientCommunicationChannel.Receive(TConfiguration.GetServerTcpProtocolResponseTimeout, TConfiguration.GetServerTcpProtocolInternalTimeout, MAX_DNS_BUFFER_LEN, Self.Buffer, Self.BufferLen) then begin

        QueryPerformanceCounter(T2);

        TDnsResolver.HandleDnsResponseForIPv6Tcp(Self.ServerCommunicationChannel, Now, Self.Buffer, Self.BufferLen, Self.DnsServerIndex, (T2 - T1) / TF, Self.DnsServerConfiguration);

      end else begin

        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TIPv6TcpIPv4TcpDnsForwarder.Execute: No response received from server while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + '.');

      end;

    finally

      ClientCommunicationChannel.Free;

    end;

  except

    on E: Exception do if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'TIPv6TcpIPv4TcpDnsForwarder.Execute: The following error occurred while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + ': ' + E.Message);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TIPv6TcpIPv4TcpDnsForwarder.Destroy;

begin

  TMemoryManager.FreeMemory(Self.Buffer, MAX_DNS_BUFFER_LEN);

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv6TcpIPv6TcpDnsForwarder.Create(ServerCommunicationChannel: TIPv6TcpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);

begin

  inherited Create(True); Self.FreeOnTerminate := True;

  Self.ServerCommunicationChannel := ServerCommunicationChannel; Self.ReferenceTime := ReferenceTime; Self.DnsServerIndex := DnsServerIndex; Self.DnsServerConfiguration := DnsServerConfiguration; Self.Buffer := TMemoryManager.GetMemory(MAX_DNS_BUFFER_LEN); Move(Buffer^, Self.Buffer^, BufferLen); Self.BufferLen := BufferLen; Self.SessionId := SessionId;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv6TcpIPv6TcpDnsForwarder.Execute;

var
  ClientCommunicationChannel: TIPv6TcpCommunicationChannel; T1, T2: Int64;

begin

  try

    ClientCommunicationChannel := TIPv6TcpCommunicationChannel.Create;

    try

      QueryPerformanceCounter(T1);

      ClientCommunicationChannel.Connect(Self.DnsServerConfiguration.Address.IPv6Address, Self.DnsServerConfiguration.Port);

      ClientCommunicationChannel.Send(Self.Buffer, Self.BufferLen);

      if ClientCommunicationChannel.Receive(TConfiguration.GetServerTcpProtocolResponseTimeout, TConfiguration.GetServerTcpProtocolInternalTimeout, MAX_DNS_BUFFER_LEN, Self.Buffer, Self.BufferLen) then begin

        QueryPerformanceCounter(T2);

        TDnsResolver.HandleDnsResponseForIPv6Tcp(Self.ServerCommunicationChannel, Now, Self.Buffer, Self.BufferLen, Self.DnsServerIndex, (T2 - T1) / TF, Self.DnsServerConfiguration);

      end else begin

        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TIPv6TcpIPv6TcpDnsForwarder.Execute: No response received from server while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + '.');

      end;

    finally

      ClientCommunicationChannel.Free;

    end;

  except

    on E: Exception do if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'TIPv6TcpIPv6TcpDnsForwarder.Execute: The following error occurred while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + ': ' + E.Message);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TIPv6TcpIPv6TcpDnsForwarder.Destroy;

begin

  TMemoryManager.FreeMemory(Self.Buffer, MAX_DNS_BUFFER_LEN);

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv4UdpIPv4Socks5DnsForwarder.Create(ServerCommunicationChannel: TIPv4UdpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);

begin

  inherited Create(True); Self.FreeOnTerminate := True;

  Self.ServerCommunicationChannel := ServerCommunicationChannel; Self.ReferenceTime := ReferenceTime; Self.DnsServerIndex := DnsServerIndex; Self.DnsServerConfiguration := DnsServerConfiguration; Self.Buffer := TMemoryManager.GetMemory(MAX_DNS_BUFFER_LEN); Move(Buffer^, Self.Buffer^, BufferLen); Self.BufferLen := BufferLen; Self.SessionId := SessionId;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv4UdpIPv4Socks5DnsForwarder.Execute;

var
  ClientCommunicationChannel: TIPv4TcpCommunicationChannel; T1, T2: Int64;

begin

  try

    ClientCommunicationChannel := TIPv4TcpCommunicationChannel.Create;

    try

      QueryPerformanceCounter(T1);

      ClientCommunicationChannel.Connect(Self.DnsServerConfiguration.Socks5ProtocolProxyAddress.IPv4Address, Self.DnsServerConfiguration.Socks5ProtocolProxyPort);

      if ClientCommunicationChannel.PerformSocks5Handshake(TConfiguration.GetServerSocks5ProtocolProxyFirstByteTimeout, TConfiguration.GetServerSocks5ProtocolProxyOtherBytesTimeout, TConfiguration.GetServerSocks5ProtocolProxyRemoteConnectTimeout, Self.DnsServerConfiguration.Address, Self.DnsServerConfiguration.Port) then begin

        ClientCommunicationChannel.Send(Self.Buffer, Self.BufferLen);

        if ClientCommunicationChannel.Receive(TConfiguration.GetServerSocks5ProtocolProxyRemoteResponseTimeout, TConfiguration.GetServerSocks5ProtocolProxyOtherBytesTimeout, MAX_DNS_BUFFER_LEN, Self.Buffer, Self.BufferLen) then begin

          QueryPerformanceCounter(T2);

          TDnsResolver.HandleDnsResponseForIPv4Udp(Self.ServerCommunicationChannel, Now, Self.Buffer, Self.BufferLen, Self.DnsServerIndex, (T2 - T1) / TF, Self.DnsServerConfiguration);

        end else begin

          if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TIPv4UdpIPv4Socks5DnsForwarder.Execute: No response received from server while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + '.');

        end;

      end else begin

        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TIPv4UdpIPv4Socks5DnsForwarder.Execute: No response received from server while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + '.');

      end;

    finally

      ClientCommunicationChannel.Free;

    end;

  except

    on E: Exception do if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'TIPv4UdpIPv4Socks5DnsForwarder.Execute: The following error occurred while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + ': ' + E.Message);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TIPv4UdpIPv4Socks5DnsForwarder.Destroy;

begin

  TMemoryManager.FreeMemory(Self.Buffer, MAX_DNS_BUFFER_LEN);

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv4UdpIPv6Socks5DnsForwarder.Create(ServerCommunicationChannel: TIPv4UdpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);

begin

  inherited Create(True); Self.FreeOnTerminate := True;

  Self.ServerCommunicationChannel := ServerCommunicationChannel; Self.ReferenceTime := ReferenceTime; Self.DnsServerIndex := DnsServerIndex; Self.DnsServerConfiguration := DnsServerConfiguration; Self.Buffer := TMemoryManager.GetMemory(MAX_DNS_BUFFER_LEN); Move(Buffer^, Self.Buffer^, BufferLen); Self.BufferLen := BufferLen; Self.SessionId := SessionId;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv4UdpIPv6Socks5DnsForwarder.Execute;

var
  ClientCommunicationChannel: TIPv6TcpCommunicationChannel; T1, T2: Int64;

begin

  try

    ClientCommunicationChannel := TIPv6TcpCommunicationChannel.Create;

    try

      QueryPerformanceCounter(T1);

      ClientCommunicationChannel.Connect(Self.DnsServerConfiguration.Socks5ProtocolProxyAddress.IPv6Address, Self.DnsServerConfiguration.Socks5ProtocolProxyPort);

      if ClientCommunicationChannel.PerformSocks5Handshake(TConfiguration.GetServerSocks5ProtocolProxyFirstByteTimeout, TConfiguration.GetServerSocks5ProtocolProxyOtherBytesTimeout, TConfiguration.GetServerSocks5ProtocolProxyRemoteConnectTimeout, Self.DnsServerConfiguration.Address, Self.DnsServerConfiguration.Port) then begin

        ClientCommunicationChannel.Send(Self.Buffer, Self.BufferLen);

        if ClientCommunicationChannel.Receive(TConfiguration.GetServerSocks5ProtocolProxyRemoteResponseTimeout, TConfiguration.GetServerSocks5ProtocolProxyOtherBytesTimeout, MAX_DNS_BUFFER_LEN, Self.Buffer, Self.BufferLen) then begin

          QueryPerformanceCounter(T2);

          TDnsResolver.HandleDnsResponseForIPv4Udp(Self.ServerCommunicationChannel, Now, Self.Buffer, Self.BufferLen, Self.DnsServerIndex, (T2 - T1) / TF, Self.DnsServerConfiguration);

        end else begin

          if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TIPv4UdpIPv6Socks5DnsForwarder.Execute: No response received from server while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + '.');

        end;

      end else begin

        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TIPv4UdpIPv6Socks5DnsForwarder.Execute: No response received from server while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + '.');

      end;

    finally

      ClientCommunicationChannel.Free;

    end;

  except

    on E: Exception do if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'TIPv4UdpIPv6Socks5DnsForwarder.Execute: The following error occurred while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + ': ' + E.Message);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TIPv4UdpIPv6Socks5DnsForwarder.Destroy;

begin

  TMemoryManager.FreeMemory(Self.Buffer, MAX_DNS_BUFFER_LEN);

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv6UdpIPv4Socks5DnsForwarder.Create(ServerCommunicationChannel: TIPv6UdpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);

begin

  inherited Create(True); Self.FreeOnTerminate := True;

  Self.ServerCommunicationChannel := ServerCommunicationChannel; Self.ReferenceTime := ReferenceTime; Self.DnsServerIndex := DnsServerIndex; Self.DnsServerConfiguration := DnsServerConfiguration; Self.Buffer := TMemoryManager.GetMemory(MAX_DNS_BUFFER_LEN); Move(Buffer^, Self.Buffer^, BufferLen); Self.BufferLen := BufferLen; Self.SessionId := SessionId;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv6UdpIPv4Socks5DnsForwarder.Execute;

var
  ClientCommunicationChannel: TIPv4TcpCommunicationChannel; T1, T2: Int64;

begin

  try

    ClientCommunicationChannel := TIPv4TcpCommunicationChannel.Create;

    try

      QueryPerformanceCounter(T1);

      ClientCommunicationChannel.Connect(Self.DnsServerConfiguration.Socks5ProtocolProxyAddress.IPv4Address, Self.DnsServerConfiguration.Socks5ProtocolProxyPort);

      if ClientCommunicationChannel.PerformSocks5Handshake(TConfiguration.GetServerSocks5ProtocolProxyFirstByteTimeout, TConfiguration.GetServerSocks5ProtocolProxyOtherBytesTimeout, TConfiguration.GetServerSocks5ProtocolProxyRemoteConnectTimeout, Self.DnsServerConfiguration.Address, Self.DnsServerConfiguration.Port) then begin

        ClientCommunicationChannel.Send(Self.Buffer, Self.BufferLen);

        if ClientCommunicationChannel.Receive(TConfiguration.GetServerSocks5ProtocolProxyRemoteResponseTimeout, TConfiguration.GetServerSocks5ProtocolProxyOtherBytesTimeout, MAX_DNS_BUFFER_LEN, Self.Buffer, Self.BufferLen) then begin

          QueryPerformanceCounter(T2);

          TDnsResolver.HandleDnsResponseForIPv6Udp(Self.ServerCommunicationChannel, Now, Self.Buffer, Self.BufferLen, Self.DnsServerIndex, (T2 - T1) / TF, Self.DnsServerConfiguration);

        end else begin

          if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TIPv6UdpIPv4Socks5DnsForwarder.Execute: No response received from server while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + '.');

        end;

      end else begin

        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TIPv6UdpIPv4Socks5DnsForwarder.Execute: No response received from server while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + '.');

      end;

    finally

      ClientCommunicationChannel.Free;

    end;

  except

    on E: Exception do if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'TIPv6UdpIPv4Socks5DnsForwarder.Execute: The following error occurred while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + ': ' + E.Message);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TIPv6UdpIPv4Socks5DnsForwarder.Destroy;

begin

  TMemoryManager.FreeMemory(Self.Buffer, MAX_DNS_BUFFER_LEN);

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv6UdpIPv6Socks5DnsForwarder.Create(ServerCommunicationChannel: TIPv6UdpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);

begin

  inherited Create(True); Self.FreeOnTerminate := True;

  Self.ServerCommunicationChannel := ServerCommunicationChannel; Self.ReferenceTime := ReferenceTime; Self.DnsServerIndex := DnsServerIndex; Self.DnsServerConfiguration := DnsServerConfiguration; Self.Buffer := TMemoryManager.GetMemory(MAX_DNS_BUFFER_LEN); Move(Buffer^, Self.Buffer^, BufferLen); Self.BufferLen := BufferLen; Self.SessionId := SessionId;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv6UdpIPv6Socks5DnsForwarder.Execute;

var
  ClientCommunicationChannel: TIPv6TcpCommunicationChannel; T1, T2: Int64;

begin

  try

    ClientCommunicationChannel := TIPv6TcpCommunicationChannel.Create;

    try

      QueryPerformanceCounter(T1);

      ClientCommunicationChannel.Connect(Self.DnsServerConfiguration.Socks5ProtocolProxyAddress.IPv6Address, Self.DnsServerConfiguration.Socks5ProtocolProxyPort);

      if ClientCommunicationChannel.PerformSocks5Handshake(TConfiguration.GetServerSocks5ProtocolProxyFirstByteTimeout, TConfiguration.GetServerSocks5ProtocolProxyOtherBytesTimeout, TConfiguration.GetServerSocks5ProtocolProxyRemoteConnectTimeout, Self.DnsServerConfiguration.Address, Self.DnsServerConfiguration.Port) then begin

        ClientCommunicationChannel.Send(Self.Buffer, Self.BufferLen);

        if ClientCommunicationChannel.Receive(TConfiguration.GetServerSocks5ProtocolProxyRemoteResponseTimeout, TConfiguration.GetServerSocks5ProtocolProxyOtherBytesTimeout, MAX_DNS_BUFFER_LEN, Self.Buffer, Self.BufferLen) then begin

          QueryPerformanceCounter(T2);

          TDnsResolver.HandleDnsResponseForIPv6Udp(Self.ServerCommunicationChannel, Now, Self.Buffer, Self.BufferLen, Self.DnsServerIndex, (T2 - T1) / TF, Self.DnsServerConfiguration);

        end else begin

          if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TIPv6UdpIPv6Socks5DnsForwarder.Execute: No response received from server while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + '.');

        end;

      end else begin

        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TIPv6UdpIPv6Socks5DnsForwarder.Execute: No response received from server while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + '.');

      end;

    finally

      ClientCommunicationChannel.Free;

    end;

  except

    on E: Exception do if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'TIPv6UdpIPv6Socks5DnsForwarder.Execute: The following error occurred while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + ': ' + E.Message);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TIPv6UdpIPv6Socks5DnsForwarder.Destroy;

begin

  TMemoryManager.FreeMemory(Self.Buffer, MAX_DNS_BUFFER_LEN);

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv4TcpIPv4Socks5DnsForwarder.Create(ServerCommunicationChannel: TIPv4TcpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);

begin

  inherited Create(True); Self.FreeOnTerminate := True;

  Self.ServerCommunicationChannel := ServerCommunicationChannel; Self.ReferenceTime := ReferenceTime; Self.DnsServerIndex := DnsServerIndex; Self.DnsServerConfiguration := DnsServerConfiguration; Self.Buffer := TMemoryManager.GetMemory(MAX_DNS_BUFFER_LEN); Move(Buffer^, Self.Buffer^, BufferLen); Self.BufferLen := BufferLen; Self.SessionId := SessionId;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv4TcpIPv4Socks5DnsForwarder.Execute;

var
  ClientCommunicationChannel: TIPv4TcpCommunicationChannel; T1, T2: Int64;

begin

  try

    ClientCommunicationChannel := TIPv4TcpCommunicationChannel.Create;

    try

      QueryPerformanceCounter(T1);

      ClientCommunicationChannel.Connect(Self.DnsServerConfiguration.Socks5ProtocolProxyAddress.IPv4Address, Self.DnsServerConfiguration.Socks5ProtocolProxyPort);

      if ClientCommunicationChannel.PerformSocks5Handshake(TConfiguration.GetServerSocks5ProtocolProxyFirstByteTimeout, TConfiguration.GetServerSocks5ProtocolProxyOtherBytesTimeout, TConfiguration.GetServerSocks5ProtocolProxyRemoteConnectTimeout, Self.DnsServerConfiguration.Address, Self.DnsServerConfiguration.Port) then begin

        ClientCommunicationChannel.Send(Self.Buffer, Self.BufferLen);

        if ClientCommunicationChannel.Receive(TConfiguration.GetServerSocks5ProtocolProxyRemoteResponseTimeout, TConfiguration.GetServerSocks5ProtocolProxyOtherBytesTimeout, MAX_DNS_BUFFER_LEN, Self.Buffer, Self.BufferLen) then begin

          QueryPerformanceCounter(T2);

          TDnsResolver.HandleDnsResponseForIPv4Tcp(Self.ServerCommunicationChannel, Now, Self.Buffer, Self.BufferLen, Self.DnsServerIndex, (T2 - T1) / TF, Self.DnsServerConfiguration);

        end else begin

          if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TIPv4TcpIPv4Socks5DnsForwarder.Execute: No response received from server while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + '.');

        end;

      end else begin

        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TIPv4TcpIPv4Socks5DnsForwarder.Execute: No response received from server while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + '.');

      end;

    finally

      ClientCommunicationChannel.Free;

    end;

  except

    on E: Exception do if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'TIPv4TcpIPv4Socks5DnsForwarder.Execute: The following error occurred while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + ': ' + E.Message);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TIPv4TcpIPv4Socks5DnsForwarder.Destroy;

begin

  TMemoryManager.FreeMemory(Self.Buffer, MAX_DNS_BUFFER_LEN);

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv4TcpIPv6Socks5DnsForwarder.Create(ServerCommunicationChannel: TIPv4TcpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);

begin

  inherited Create(True); Self.FreeOnTerminate := True;

  Self.ServerCommunicationChannel := ServerCommunicationChannel; Self.ReferenceTime := ReferenceTime; Self.DnsServerIndex := DnsServerIndex; Self.DnsServerConfiguration := DnsServerConfiguration; Self.Buffer := TMemoryManager.GetMemory(MAX_DNS_BUFFER_LEN); Move(Buffer^, Self.Buffer^, BufferLen); Self.BufferLen := BufferLen; Self.SessionId := SessionId;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv4TcpIPv6Socks5DnsForwarder.Execute;

var
  ClientCommunicationChannel: TIPv6TcpCommunicationChannel; T1, T2: Int64;

begin

  try

    ClientCommunicationChannel := TIPv6TcpCommunicationChannel.Create;

    try

      QueryPerformanceCounter(T1);

      ClientCommunicationChannel.Connect(Self.DnsServerConfiguration.Socks5ProtocolProxyAddress.IPv6Address, Self.DnsServerConfiguration.Socks5ProtocolProxyPort);

      if ClientCommunicationChannel.PerformSocks5Handshake(TConfiguration.GetServerSocks5ProtocolProxyFirstByteTimeout, TConfiguration.GetServerSocks5ProtocolProxyOtherBytesTimeout, TConfiguration.GetServerSocks5ProtocolProxyRemoteConnectTimeout, Self.DnsServerConfiguration.Address, Self.DnsServerConfiguration.Port) then begin

        ClientCommunicationChannel.Send(Self.Buffer, Self.BufferLen);

        if ClientCommunicationChannel.Receive(TConfiguration.GetServerSocks5ProtocolProxyRemoteResponseTimeout, TConfiguration.GetServerSocks5ProtocolProxyOtherBytesTimeout, MAX_DNS_BUFFER_LEN, Self.Buffer, Self.BufferLen) then begin

          QueryPerformanceCounter(T2);

          TDnsResolver.HandleDnsResponseForIPv4Tcp(Self.ServerCommunicationChannel, Now, Self.Buffer, Self.BufferLen, Self.DnsServerIndex, (T2 - T1) / TF, Self.DnsServerConfiguration);

        end else begin

          if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TIPv4TcpIPv6Socks5DnsForwarder.Execute: No response received from server while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + '.');

        end;

      end else begin

        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TIPv4TcpIPv6Socks5DnsForwarder.Execute: No response received from server while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + '.');

      end;

    finally

      ClientCommunicationChannel.Free;

    end;

  except

    on E: Exception do if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'TIPv6UdpIPv6Socks5DnsForwarder.Execute: The following error occurred while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + ': ' + E.Message);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TIPv4TcpIPv6Socks5DnsForwarder.Destroy;

begin

  TMemoryManager.FreeMemory(Self.Buffer, MAX_DNS_BUFFER_LEN);

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv6TcpIPv4Socks5DnsForwarder.Create(ServerCommunicationChannel: TIPv6TcpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);

begin

  inherited Create(True); Self.FreeOnTerminate := True;

  Self.ServerCommunicationChannel := ServerCommunicationChannel; Self.ReferenceTime := ReferenceTime; Self.DnsServerIndex := DnsServerIndex; Self.DnsServerConfiguration := DnsServerConfiguration; Self.Buffer := TMemoryManager.GetMemory(MAX_DNS_BUFFER_LEN); Move(Buffer^, Self.Buffer^, BufferLen); Self.BufferLen := BufferLen; Self.SessionId := SessionId;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv6TcpIPv4Socks5DnsForwarder.Execute;

var
  ClientCommunicationChannel: TIPv4TcpCommunicationChannel; T1, T2: Int64;

begin

  try

    ClientCommunicationChannel := TIPv4TcpCommunicationChannel.Create;

    try

      QueryPerformanceCounter(T1);

      ClientCommunicationChannel.Connect(Self.DnsServerConfiguration.Socks5ProtocolProxyAddress.IPv4Address, Self.DnsServerConfiguration.Socks5ProtocolProxyPort);

      if ClientCommunicationChannel.PerformSocks5Handshake(TConfiguration.GetServerSocks5ProtocolProxyFirstByteTimeout, TConfiguration.GetServerSocks5ProtocolProxyOtherBytesTimeout, TConfiguration.GetServerSocks5ProtocolProxyRemoteConnectTimeout, Self.DnsServerConfiguration.Address, Self.DnsServerConfiguration.Port) then begin

        ClientCommunicationChannel.Send(Self.Buffer, Self.BufferLen);

        if ClientCommunicationChannel.Receive(TConfiguration.GetServerSocks5ProtocolProxyRemoteResponseTimeout, TConfiguration.GetServerSocks5ProtocolProxyOtherBytesTimeout, MAX_DNS_BUFFER_LEN, Self.Buffer, Self.BufferLen) then begin

          QueryPerformanceCounter(T2);

          TDnsResolver.HandleDnsResponseForIPv6Tcp(Self.ServerCommunicationChannel, Now, Self.Buffer, Self.BufferLen, Self.DnsServerIndex, (T2 - T1) / TF, Self.DnsServerConfiguration);

        end else begin

          if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TIPv6TcpIPv4Socks5DnsForwarder.Execute: No response received from server while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + '.');

        end;

      end else begin

        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TIPv6TcpIPv4Socks5DnsForwarder.Execute: No response received from server while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + '.');

      end;

    finally

      ClientCommunicationChannel.Free;

    end;

  except

    on E: Exception do if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'TIPv6TcpIPv4Socks5DnsForwarder.Execute: The following error occurred while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + ': ' + E.Message);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TIPv6TcpIPv4Socks5DnsForwarder.Destroy;

begin

  TMemoryManager.FreeMemory(Self.Buffer, MAX_DNS_BUFFER_LEN);

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv6TcpIPv6Socks5DnsForwarder.Create(ServerCommunicationChannel: TIPv6TcpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);

begin

  inherited Create(True); Self.FreeOnTerminate := True;

  Self.ServerCommunicationChannel := ServerCommunicationChannel; Self.ReferenceTime := ReferenceTime; Self.DnsServerIndex := DnsServerIndex; Self.DnsServerConfiguration := DnsServerConfiguration; Self.Buffer := TMemoryManager.GetMemory(MAX_DNS_BUFFER_LEN); Move(Buffer^, Self.Buffer^, BufferLen); Self.BufferLen := BufferLen; Self.SessionId := SessionId;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv6TcpIPv6Socks5DnsForwarder.Execute;

var
  ClientCommunicationChannel: TIPv6TcpCommunicationChannel; T1, T2: Int64;

begin

  try

    ClientCommunicationChannel := TIPv6TcpCommunicationChannel.Create;

    try

      QueryPerformanceCounter(T1);

      ClientCommunicationChannel.Connect(Self.DnsServerConfiguration.Socks5ProtocolProxyAddress.IPv6Address, Self.DnsServerConfiguration.Socks5ProtocolProxyPort);

      if ClientCommunicationChannel.PerformSocks5Handshake(TConfiguration.GetServerSocks5ProtocolProxyFirstByteTimeout, TConfiguration.GetServerSocks5ProtocolProxyOtherBytesTimeout, TConfiguration.GetServerSocks5ProtocolProxyRemoteConnectTimeout, Self.DnsServerConfiguration.Address, Self.DnsServerConfiguration.Port) then begin

        ClientCommunicationChannel.Send(Self.Buffer, Self.BufferLen);

        if ClientCommunicationChannel.Receive(TConfiguration.GetServerSocks5ProtocolProxyRemoteResponseTimeout, TConfiguration.GetServerSocks5ProtocolProxyOtherBytesTimeout, MAX_DNS_BUFFER_LEN, Self.Buffer, Self.BufferLen) then begin

          QueryPerformanceCounter(T2);

          TDnsResolver.HandleDnsResponseForIPv6Tcp(Self.ServerCommunicationChannel, Now, Self.Buffer, Self.BufferLen, Self.DnsServerIndex, (T2 - T1) / TF, Self.DnsServerConfiguration);

        end else begin

          if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TIPv6TcpIPv6Socks5DnsForwarder.Execute: No response received from server while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + '.');

        end;

      end else begin

        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TIPv6TcpIPv6Socks5DnsForwarder.Execute: No response received from server while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + '.');

      end;

    finally

      ClientCommunicationChannel.Free;

    end;

  except

    on E: Exception do if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'TIPv6TcpIPv6Socks5DnsForwarder.Execute: The following error occurred while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + ': ' + E.Message);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TIPv6TcpIPv6Socks5DnsForwarder.Destroy;

begin

  TMemoryManager.FreeMemory(Self.Buffer, MAX_DNS_BUFFER_LEN);

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv4UdpDnsOverHttpsDnsForwarder.Create(ServerCommunicationChannel: TIPv4UdpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);

begin

  inherited Create(True); Self.FreeOnTerminate := True;

  Self.ServerCommunicationChannel := ServerCommunicationChannel; Self.ReferenceTime := ReferenceTime; Self.DnsServerIndex := DnsServerIndex; Self.DnsServerConfiguration := DnsServerConfiguration; Self.Buffer := TMemoryManager.GetMemory(MAX_DNS_BUFFER_LEN); Move(Buffer^, Self.Buffer^, BufferLen); Self.BufferLen := BufferLen; Self.SessionId := SessionId;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv4UdpDnsOverHttpsDnsForwarder.Execute;

var
  ClientCommunicationChannel: TDnsOverHttpsCommunicationChannel; T1, T2: Int64;

begin

  try

    ClientCommunicationChannel := TDnsOverHttpsCommunicationChannel.Create;

    try

      if Self.DnsServerConfiguration.DnsOverHttpsProtocolUseWinHttp then begin

        QueryPerformanceCounter(T1);

        if ClientCommunicationChannel.SendAndReceiveUsingWinHttp(Self.Buffer, Self.BufferLen, Self.DnsServerConfiguration.DnsOverHttpsProtocolHost, Self.DnsServerConfiguration.Port, Self.DnsServerConfiguration.DnsOverHttpsProtocolPath, Self.DnsServerConfiguration.DnsOverHttpsProtocolHost, Self.DnsServerConfiguration.DnsOverHttpsProtocolConnectionType, Self.DnsServerConfiguration.DnsOverHttpsProtocolReuseConnections, 0, MAX_DNS_BUFFER_LEN, Self.Buffer, Self.BufferLen) then begin

          QueryPerformanceCounter(T2);

          TDnsResolver.HandleDnsResponseForIPv4Udp(Self.ServerCommunicationChannel, Now, Self.Buffer, Self.BufferLen, Self.DnsServerIndex, (T2 - T1) / TF, Self.DnsServerConfiguration);

        end else begin

          if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TIPv4UdpDnsOverHttpsDnsForwarder.Execute: No response received from server while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + '.');

        end;

      end else begin

        QueryPerformanceCounter(T1);

        if ClientCommunicationChannel.SendAndReceiveUsingWinInet(Self.Buffer, Self.BufferLen, Self.DnsServerConfiguration.DnsOverHttpsProtocolHost, Self.DnsServerConfiguration.Port, Self.DnsServerConfiguration.DnsOverHttpsProtocolPath, Self.DnsServerConfiguration.DnsOverHttpsProtocolHost, Self.DnsServerConfiguration.DnsOverHttpsProtocolConnectionType, Self.DnsServerConfiguration.DnsOverHttpsProtocolReuseConnections, 0, MAX_DNS_BUFFER_LEN, Self.Buffer, Self.BufferLen) then begin

          QueryPerformanceCounter(T2);

          TDnsResolver.HandleDnsResponseForIPv4Udp(Self.ServerCommunicationChannel, Now, Self.Buffer, Self.BufferLen, Self.DnsServerIndex, (T2 - T1) / TF, Self.DnsServerConfiguration);

        end else begin

          if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TIPv4UdpDnsOverHttpsDnsForwarder.Execute: No response received from server while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + '.');

        end;

      end;

    finally

      ClientCommunicationChannel.Free;

    end;

  except

    on E: Exception do if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'TIPv4UdpDnsOverHttpsDnsForwarder.Execute: The following error occurred while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + ': ' + E.Message);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TIPv4UdpDnsOverHttpsDnsForwarder.Destroy;

begin

  TMemoryManager.FreeMemory(Self.Buffer, MAX_DNS_BUFFER_LEN);

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv6UdpDnsOverHttpsDnsForwarder.Create(ServerCommunicationChannel: TIPv6UdpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);

begin

  inherited Create(True); Self.FreeOnTerminate := True;

  Self.ServerCommunicationChannel := ServerCommunicationChannel; Self.ReferenceTime := ReferenceTime; Self.DnsServerIndex := DnsServerIndex; Self.DnsServerConfiguration := DnsServerConfiguration; Self.Buffer := TMemoryManager.GetMemory(MAX_DNS_BUFFER_LEN); Move(Buffer^, Self.Buffer^, BufferLen); Self.BufferLen := BufferLen; Self.SessionId := SessionId;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv6UdpDnsOverHttpsDnsForwarder.Execute;

var
  ClientCommunicationChannel: TDnsOverHttpsCommunicationChannel; T1, T2: Int64;

begin

  try

    ClientCommunicationChannel := TDnsOverHttpsCommunicationChannel.Create;

    try

      if Self.DnsServerConfiguration.DnsOverHttpsProtocolUseWinHttp then begin

        QueryPerformanceCounter(T1);

        if ClientCommunicationChannel.SendAndReceiveUsingWinHttp(Self.Buffer, Self.BufferLen, Self.DnsServerConfiguration.DnsOverHttpsProtocolHost, Self.DnsServerConfiguration.Port, Self.DnsServerConfiguration.DnsOverHttpsProtocolPath, Self.DnsServerConfiguration.DnsOverHttpsProtocolHost, Self.DnsServerConfiguration.DnsOverHttpsProtocolConnectionType, Self.DnsServerConfiguration.DnsOverHttpsProtocolReuseConnections, 0, MAX_DNS_BUFFER_LEN, Self.Buffer, Self.BufferLen) then begin

          QueryPerformanceCounter(T2);

          TDnsResolver.HandleDnsResponseForIPv6Udp(Self.ServerCommunicationChannel, Now, Self.Buffer, Self.BufferLen, Self.DnsServerIndex, (T2 - T1) / TF, Self.DnsServerConfiguration);

        end else begin

          if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TIPv6UdpDnsOverHttpsDnsForwarder.Execute: No response received from server while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + '.');

        end;

      end else begin

        QueryPerformanceCounter(T1);

        if ClientCommunicationChannel.SendAndReceiveUsingWinInet(Self.Buffer, Self.BufferLen, Self.DnsServerConfiguration.DnsOverHttpsProtocolHost, Self.DnsServerConfiguration.Port, Self.DnsServerConfiguration.DnsOverHttpsProtocolPath, Self.DnsServerConfiguration.DnsOverHttpsProtocolHost, Self.DnsServerConfiguration.DnsOverHttpsProtocolConnectionType, Self.DnsServerConfiguration.DnsOverHttpsProtocolReuseConnections, 0, MAX_DNS_BUFFER_LEN, Self.Buffer, Self.BufferLen) then begin

          QueryPerformanceCounter(T2);

          TDnsResolver.HandleDnsResponseForIPv6Udp(Self.ServerCommunicationChannel, Now, Self.Buffer, Self.BufferLen, Self.DnsServerIndex, (T2 - T1) / TF, Self.DnsServerConfiguration);

        end else begin

          if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TIPv6UdpDnsOverHttpsDnsForwarder.Execute: No response received from server while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + '.');

        end;

      end;

    finally

      ClientCommunicationChannel.Free;

    end;

  except

    on E: Exception do if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'TIPv6UdpDnsOverHttpsDnsForwarder.Execute: The following error occurred while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + ': ' + E.Message);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TIPv6UdpDnsOverHttpsDnsForwarder.Destroy;

begin

  TMemoryManager.FreeMemory(Self.Buffer, MAX_DNS_BUFFER_LEN);

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv4TcpDnsOverHttpsDnsForwarder.Create(ServerCommunicationChannel: TIPv4TcpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);

begin

  inherited Create(True); Self.FreeOnTerminate := True;

  Self.ServerCommunicationChannel := ServerCommunicationChannel; Self.ReferenceTime := ReferenceTime; Self.DnsServerIndex := DnsServerIndex; Self.DnsServerConfiguration := DnsServerConfiguration; Self.Buffer := TMemoryManager.GetMemory(MAX_DNS_BUFFER_LEN); Move(Buffer^, Self.Buffer^, BufferLen); Self.BufferLen := BufferLen; Self.SessionId := SessionId;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv4TcpDnsOverHttpsDnsForwarder.Execute;

var
  ClientCommunicationChannel: TDnsOverHttpsCommunicationChannel; T1, T2: Int64;

begin

  try

    ClientCommunicationChannel := TDnsOverHttpsCommunicationChannel.Create;

    try

      if Self.DnsServerConfiguration.DnsOverHttpsProtocolUseWinHttp then begin

        QueryPerformanceCounter(T1);

        if ClientCommunicationChannel.SendAndReceiveUsingWinHttp(Self.Buffer, Self.BufferLen, Self.DnsServerConfiguration.DnsOverHttpsProtocolHost, Self.DnsServerConfiguration.Port, Self.DnsServerConfiguration.DnsOverHttpsProtocolPath, Self.DnsServerConfiguration.DnsOverHttpsProtocolHost, Self.DnsServerConfiguration.DnsOverHttpsProtocolConnectionType, Self.DnsServerConfiguration.DnsOverHttpsProtocolReuseConnections, 0, MAX_DNS_BUFFER_LEN, Self.Buffer, Self.BufferLen) then begin

          QueryPerformanceCounter(T2);

          TDnsResolver.HandleDnsResponseForIPv4Tcp(Self.ServerCommunicationChannel, Now, Self.Buffer, Self.BufferLen, Self.DnsServerIndex, (T2 - T1) / TF, Self.DnsServerConfiguration);

        end else begin

          if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TIPv4TcpDnsOverHttpsDnsForwarder.Execute: No response received from server while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + '.');

        end;

      end else begin

        QueryPerformanceCounter(T1);

        if ClientCommunicationChannel.SendAndReceiveUsingWinInet(Self.Buffer, Self.BufferLen, Self.DnsServerConfiguration.DnsOverHttpsProtocolHost, Self.DnsServerConfiguration.Port, Self.DnsServerConfiguration.DnsOverHttpsProtocolPath, Self.DnsServerConfiguration.DnsOverHttpsProtocolHost, Self.DnsServerConfiguration.DnsOverHttpsProtocolConnectionType, Self.DnsServerConfiguration.DnsOverHttpsProtocolReuseConnections, 0, MAX_DNS_BUFFER_LEN, Self.Buffer, Self.BufferLen) then begin

          QueryPerformanceCounter(T2);

          TDnsResolver.HandleDnsResponseForIPv4Tcp(Self.ServerCommunicationChannel, Now, Self.Buffer, Self.BufferLen, Self.DnsServerIndex, (T2 - T1) / TF, Self.DnsServerConfiguration);

        end else begin

          if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TIPv4TcpDnsOverHttpsDnsForwarder.Execute: No response received from server while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + '.');

        end;

      end;

    finally

      ClientCommunicationChannel.Free;

    end;

  except

    on E: Exception do if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'TIPv4TcpDnsOverHttpsDnsForwarder.Execute: The following error occurred while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + ': ' + E.Message);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TIPv4TcpDnsOverHttpsDnsForwarder.Destroy;

begin

  TMemoryManager.FreeMemory(Self.Buffer, MAX_DNS_BUFFER_LEN);

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv6TcpDnsOverHttpsDnsForwarder.Create(ServerCommunicationChannel: TIPv6TcpCommunicationChannel; ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);

begin

  inherited Create(True); Self.FreeOnTerminate := True;

  Self.ServerCommunicationChannel := ServerCommunicationChannel; Self.ReferenceTime := ReferenceTime; Self.DnsServerIndex := DnsServerIndex; Self.DnsServerConfiguration := DnsServerConfiguration; Self.Buffer := TMemoryManager.GetMemory(MAX_DNS_BUFFER_LEN); Move(Buffer^, Self.Buffer^, BufferLen); Self.BufferLen := BufferLen; Self.SessionId := SessionId;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv6TcpDnsOverHttpsDnsForwarder.Execute;

var
  ClientCommunicationChannel: TDnsOverHttpsCommunicationChannel; T1, T2: Int64;

begin

  try

    ClientCommunicationChannel := TDnsOverHttpsCommunicationChannel.Create;

    try

      if Self.DnsServerConfiguration.DnsOverHttpsProtocolUseWinHttp then begin

        QueryPerformanceCounter(T1);

        if ClientCommunicationChannel.SendAndReceiveUsingWinHttp(Self.Buffer, Self.BufferLen, Self.DnsServerConfiguration.DnsOverHttpsProtocolHost, Self.DnsServerConfiguration.Port, Self.DnsServerConfiguration.DnsOverHttpsProtocolPath, Self.DnsServerConfiguration.DnsOverHttpsProtocolHost, Self.DnsServerConfiguration.DnsOverHttpsProtocolConnectionType, Self.DnsServerConfiguration.DnsOverHttpsProtocolReuseConnections, 0, MAX_DNS_BUFFER_LEN, Self.Buffer, Self.BufferLen) then begin

          QueryPerformanceCounter(T2);

          TDnsResolver.HandleDnsResponseForIPv6Tcp(Self.ServerCommunicationChannel, Now, Self.Buffer, Self.BufferLen, Self.DnsServerIndex, (T2 - T1) / TF, Self.DnsServerConfiguration);

        end else begin

          if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TIPv6TcpDnsOverHttpsDnsForwarder.Execute: No response received from server while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + '.');

        end;

      end else begin

        QueryPerformanceCounter(T1);

        if ClientCommunicationChannel.SendAndReceiveUsingWinInet(Self.Buffer, Self.BufferLen, Self.DnsServerConfiguration.DnsOverHttpsProtocolHost, Self.DnsServerConfiguration.Port, Self.DnsServerConfiguration.DnsOverHttpsProtocolPath, Self.DnsServerConfiguration.DnsOverHttpsProtocolHost, Self.DnsServerConfiguration.DnsOverHttpsProtocolConnectionType, Self.DnsServerConfiguration.DnsOverHttpsProtocolReuseConnections, 0, MAX_DNS_BUFFER_LEN, Self.Buffer, Self.BufferLen) then begin

          QueryPerformanceCounter(T2);

          TDnsResolver.HandleDnsResponseForIPv6Tcp(Self.ServerCommunicationChannel, Now, Self.Buffer, Self.BufferLen, Self.DnsServerIndex, (T2 - T1) / TF, Self.DnsServerConfiguration);

        end else begin

          if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TIPv6TcpDnsOverHttpsDnsForwarder.Execute: No response received from server while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + '.');

        end;

      end;

    finally

      ClientCommunicationChannel.Free;

    end;

  except

    on E: Exception do if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'TIPv6TcpDnsOverHttpsDnsForwarder.Execute: The following error occurred while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + ': ' + E.Message);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TIPv6TcpDnsOverHttpsDnsForwarder.Destroy;

begin

  TMemoryManager.FreeMemory(Self.Buffer, MAX_DNS_BUFFER_LEN);

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

begin

  QueryPerformanceFrequency(TF);

end.
