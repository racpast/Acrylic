// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

unit
  HostsCacheBinaryTrees;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

interface

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  IpUtils,
  MD5,
  MemoryStore;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  PHostsCacheIPv4AddressBinaryTreeItem = ^THostsCacheIPv4AddressBinaryTreeItem;
  THostsCacheIPv4AddressBinaryTreeItem = packed record
    Hash : TMD5Digest;
    Data : TIPv4Address;
    L    : PHostsCacheIPv4AddressBinaryTreeItem;
    R    : PHostsCacheIPv4AddressBinaryTreeItem;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  THostsCacheIPv4AddressBinaryTree = class
    private
      MemoryStore: TType1MemoryStore;
    private
      BinaryTreeRoot: PHostsCacheIPv4AddressBinaryTreeItem;
    public
      constructor Create(MemoryStore: TType1MemoryStore);
      procedure   Add(Name: String; Data: TIPv4Address);
      function    Find(Name: String; var Data: TIPv4Address): Boolean;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  PHostsCacheIPv6AddressBinaryTreeItem = ^THostsCacheIPv6AddressBinaryTreeItem;
  THostsCacheIPv6AddressBinaryTreeItem = packed record
    Hash : TMD5Digest;
    Data : PIPv6Address;
    L    : PHostsCacheIPv6AddressBinaryTreeItem;
    R    : PHostsCacheIPv6AddressBinaryTreeItem;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  THostsCacheIPv6AddressBinaryTree = class
    private
      MemoryStore: TType1MemoryStore;
    private
      BinaryTreeRoot: PHostsCacheIPv6AddressBinaryTreeItem;
    public
      constructor Create(MemoryStore: TType1MemoryStore);
      procedure   Add(Name: String; Data: PIPv6Address);
      function    Find(Name: String; var Data: PIPv6Address): Boolean;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  PHostsCacheNameOnlyBinaryTreeItem = ^THostsCacheNameOnlyBinaryTreeItem;
  THostsCacheNameOnlyBinaryTreeItem = packed record
    Hash : TMD5Digest;
    L    : PHostsCacheNameOnlyBinaryTreeItem;
    R    : PHostsCacheNameOnlyBinaryTreeItem;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  THostsCacheNameOnlyBinaryTree = class
    private
      MemoryStore: TType1MemoryStore;
    private
      BinaryTreeRoot: PHostsCacheNameOnlyBinaryTreeItem;
    public
      constructor Create(MemoryStore: TType1MemoryStore);
      procedure   Add(Name: String);
      function    Find(Name: String): Boolean;
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
  SysUtils;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor THostsCacheIPv4AddressBinaryTree.Create(MemoryStore: TType1MemoryStore);

begin

  inherited Create;

  Self.BinaryTreeRoot := nil;

  Self.MemoryStore := MemoryStore;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure THostsCacheIPv4AddressBinaryTree.Add(Name: String; Data: TIPv4Address);

var
  Hash: TMD5Digest; BinaryTreeItem: PHostsCacheIPv4AddressBinaryTreeItem; CompareResult: Integer;

begin

  Hash := TMD5.Compute(@((LowerCase(Name))[1]), Length(Name));

  if (Self.BinaryTreeRoot <> nil) then begin

    BinaryTreeItem := Self.BinaryTreeRoot; while True do begin

      CompareResult := TMD5.Compare(Hash, BinaryTreeItem^.Hash);

      if (CompareResult > 0) then begin

        if (BinaryTreeItem^.R = nil) then begin

          BinaryTreeItem^.R := Self.MemoryStore.GetMemory(SizeOf(THostsCacheIPv4AddressBinaryTreeItem)); BinaryTreeItem^.R^.Hash := Hash; BinaryTreeItem^.R^.Data := Data; BinaryTreeItem^.R^.L := nil; BinaryTreeItem^.R^.R := nil; Exit;

        end else begin

          BinaryTreeItem := BinaryTreeItem^.R;

        end;

      end else if (CompareResult < 0) then begin

        if (BinaryTreeItem^.L = nil) then begin

          BinaryTreeItem^.L := Self.MemoryStore.GetMemory(SizeOf(THostsCacheIPv4AddressBinaryTreeItem)); BinaryTreeItem^.L^.Hash := Hash; BinaryTreeItem^.L^.Data := Data; BinaryTreeItem^.L^.L := nil; BinaryTreeItem^.L^.R := nil; Exit;

        end else begin

          BinaryTreeItem := BinaryTreeItem^.L;

        end;

      end else begin

        Exit;

      end;

    end;

  end else begin

    Self.BinaryTreeRoot := Self.MemoryStore.GetMemory(SizeOf(THostsCacheIPv4AddressBinaryTreeItem)); Self.BinaryTreeRoot^.Hash := Hash; Self.BinaryTreeRoot^.Data := Data; Self.BinaryTreeRoot^.L := nil; Self.BinaryTreeRoot^.R := nil;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function THostsCacheIPv4AddressBinaryTree.Find(Name: String; var Data: TIPv4Address): Boolean;

var
  Hash: TMD5Digest; BinaryTreeItem: PHostsCacheIPv4AddressBinaryTreeItem; CompareResult: Integer;

begin

  Result := False;

  if (Self.BinaryTreeRoot <> nil) then begin

    Hash := TMD5.Compute(@((LowerCase(Name))[1]), Length(Name));

    BinaryTreeItem := Self.BinaryTreeRoot; while True do begin

      CompareResult := TMD5.Compare(Hash, BinaryTreeItem^.Hash);

      if (CompareResult > 0) then begin

        if (BinaryTreeItem^.R <> nil) then begin

          BinaryTreeItem := BinaryTreeItem^.R;

        end else begin

          Exit;

        end;

      end else if (CompareResult < 0) then begin

        if (BinaryTreeItem^.L <> nil) then begin

          BinaryTreeItem := BinaryTreeItem^.L;

        end else begin

          Exit;

        end;

      end else begin

        Data := BinaryTreeItem^.Data; Result := True; Exit;

      end;

    end;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor THostsCacheIPv4AddressBinaryTree.Destroy;

begin

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor THostsCacheIPv6AddressBinaryTree.Create(MemoryStore: TType1MemoryStore);

begin

  inherited Create;

  Self.BinaryTreeRoot := nil;

  Self.MemoryStore := MemoryStore;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure THostsCacheIPv6AddressBinaryTree.Add(Name: String; Data: PIPv6Address);

var
  Hash: TMD5Digest; BinaryTreeItem: PHostsCacheIPv6AddressBinaryTreeItem; CompareResult: Integer;

begin

  Hash := TMD5.Compute(@((LowerCase(Name))[1]), Length(Name));

  if (Self.BinaryTreeRoot <> nil) then begin

    BinaryTreeItem := Self.BinaryTreeRoot; while True do begin

      CompareResult := TMD5.Compare(Hash, BinaryTreeItem^.Hash);

      if (CompareResult > 0) then begin

        if (BinaryTreeItem^.R = nil) then begin

          BinaryTreeItem^.R := Self.MemoryStore.GetMemory(SizeOf(THostsCacheIPv6AddressBinaryTreeItem)); BinaryTreeItem^.R^.Hash := Hash; BinaryTreeItem^.R^.Data := Data; BinaryTreeItem^.R^.L := nil; BinaryTreeItem^.R^.R := nil; Exit;

        end else begin

          BinaryTreeItem := BinaryTreeItem^.R;

        end;

      end else if (CompareResult < 0) then begin

        if (BinaryTreeItem^.L = nil) then begin

          BinaryTreeItem^.L := Self.MemoryStore.GetMemory(SizeOf(THostsCacheIPv6AddressBinaryTreeItem)); BinaryTreeItem^.L^.Hash := Hash; BinaryTreeItem^.L^.Data := Data; BinaryTreeItem^.L^.L := nil; BinaryTreeItem^.L^.R := nil; Exit;

        end else begin

          BinaryTreeItem := BinaryTreeItem^.L;

        end;

      end else begin

        Exit;

      end;

    end;

  end else begin

    Self.BinaryTreeRoot := Self.MemoryStore.GetMemory(SizeOf(THostsCacheIPv6AddressBinaryTreeItem)); Self.BinaryTreeRoot^.Hash := Hash; Self.BinaryTreeRoot^.Data := Data; Self.BinaryTreeRoot^.L := nil; Self.BinaryTreeRoot^.R := nil;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function THostsCacheIPv6AddressBinaryTree.Find(Name: String; var Data: PIPv6Address): Boolean;

var
  Hash: TMD5Digest; BinaryTreeItem: PHostsCacheIPv6AddressBinaryTreeItem; CompareResult: Integer;

begin

  Result := False;

  if (Self.BinaryTreeRoot <> nil) then begin

    Hash := TMD5.Compute(@((LowerCase(Name))[1]), Length(Name));

    BinaryTreeItem := Self.BinaryTreeRoot; while True do begin

      CompareResult := TMD5.Compare(Hash, BinaryTreeItem^.Hash);

      if (CompareResult > 0) then begin

        if (BinaryTreeItem^.R <> nil) then begin

          BinaryTreeItem := BinaryTreeItem^.R;

        end else begin

          Exit;

        end;

      end else if (CompareResult < 0) then begin

        if (BinaryTreeItem^.L <> nil) then begin

          BinaryTreeItem := BinaryTreeItem^.L;

        end else begin

          Exit;

        end;

      end else begin

        Data := BinaryTreeItem^.Data; Result := True; Exit;

      end;

    end;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor THostsCacheIPv6AddressBinaryTree.Destroy;

begin

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor THostsCacheNameOnlyBinaryTree.Create(MemoryStore: TType1MemoryStore);

begin

  inherited Create;

  Self.BinaryTreeRoot := nil;

  Self.MemoryStore := MemoryStore;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure THostsCacheNameOnlyBinaryTree.Add(Name: String);

var
  Hash: TMD5Digest; BinaryTreeItem: PHostsCacheNameOnlyBinaryTreeItem; CompareResult: Integer;

begin

  Hash := TMD5.Compute(@((LowerCase(Name))[1]), Length(Name));

  if (Self.BinaryTreeRoot <> nil) then begin

    BinaryTreeItem := Self.BinaryTreeRoot; while True do begin

      CompareResult := TMD5.Compare(Hash, BinaryTreeItem^.Hash);

      if (CompareResult > 0) then begin

        if (BinaryTreeItem^.R = nil) then begin

          BinaryTreeItem^.R := Self.MemoryStore.GetMemory(SizeOf(THostsCacheNameOnlyBinaryTreeItem)); BinaryTreeItem^.R^.Hash := Hash; BinaryTreeItem^.R^.L := nil; BinaryTreeItem^.R^.R := nil; Exit;

        end else begin

          BinaryTreeItem := BinaryTreeItem^.R;

        end;

      end else if (CompareResult < 0) then begin

        if (BinaryTreeItem^.L = nil) then begin

          BinaryTreeItem^.L := Self.MemoryStore.GetMemory(SizeOf(THostsCacheNameOnlyBinaryTreeItem)); BinaryTreeItem^.L^.Hash := Hash; BinaryTreeItem^.L^.L := nil; BinaryTreeItem^.L^.R := nil; Exit;

        end else begin

          BinaryTreeItem := BinaryTreeItem^.L;

        end;

      end else begin

        Exit;

      end;

    end;

  end else begin

    Self.BinaryTreeRoot := Self.MemoryStore.GetMemory(SizeOf(THostsCacheNameOnlyBinaryTreeItem)); Self.BinaryTreeRoot^.Hash := Hash; Self.BinaryTreeRoot^.L := nil; Self.BinaryTreeRoot^.R := nil;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function THostsCacheNameOnlyBinaryTree.Find(Name: String): Boolean;

var
  Hash: TMD5Digest; BinaryTreeItem: PHostsCacheNameOnlyBinaryTreeItem; CompareResult: Integer;

begin

  Result := False;

  if (Self.BinaryTreeRoot <> nil) then begin

    Hash := TMD5.Compute(@((LowerCase(Name))[1]), Length(Name));

    BinaryTreeItem := Self.BinaryTreeRoot; while True do begin

      CompareResult := TMD5.Compare(Hash, BinaryTreeItem^.Hash);

      if (CompareResult > 0) then begin

        if (BinaryTreeItem^.R <> nil) then begin

          BinaryTreeItem := BinaryTreeItem^.R;

        end else begin

          Exit;

        end;

      end else if (CompareResult < 0) then begin

        if (BinaryTreeItem^.L <> nil) then begin

          BinaryTreeItem := BinaryTreeItem^.L;

        end else begin

          Exit;

        end;

      end else begin

        Result := True; Exit;

      end;

    end;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor THostsCacheNameOnlyBinaryTree.Destroy;

begin

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.