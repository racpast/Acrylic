// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

unit
  MemoryStore;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

interface

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  Classes,
  Contnrs,
  SysUtils;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

const
  MEMORY_STORE_64KB_BLOCK_SIZE   = 65536;
  MEMORY_STORE_128KB_BLOCK_SIZE  = 131072;
  MEMORY_STORE_256KB_BLOCK_SIZE  = 262144;
  MEMORY_STORE_512KB_BLOCK_SIZE  = 524288;
  MEMORY_STORE_1024KB_BLOCK_SIZE = 1048576;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  IMemoryStore = interface(IInterface)
    function  GetMemory(Size: Cardinal): Pointer;
    procedure FreeMemory(Address: Pointer);
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TType1MemoryStore = class(TInterfacedObject, IMemoryStore)
    private
      MemoryBlockSize: Cardinal;
      MemoryBlockList: TList;
      PositionInCurrentMemoryBlock: Cardinal;
    public
      constructor Create(MemoryBlockSize: Cardinal);
      function    GetMemory(Size: Cardinal): Pointer;
      procedure   FreeMemory(Address: Pointer);
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TType2MemoryStore = class(TInterfacedObject, IMemoryStore)
    private
      MemoryBlockSize: Cardinal;
      MemoryBlockList: TList;
      PositionInCurrentMemoryBlock: Cardinal;
      AllocationBlockSize: Cardinal;
      AllocationBlockList: TQueue;
    public
      constructor Create(MemoryBlockSize: Cardinal; AllocationBlockSize: Cardinal);
      function    GetMemory(Size: Cardinal): Pointer;
      procedure   FreeMemory(Address: Pointer);
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
  MemoryManager;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TType1MemoryStore.Create(MemoryBlockSize: Cardinal);

begin

  Self.MemoryBlockSize := MemoryBlockSize;

  Self.MemoryBlockList := TList.Create;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TType1MemoryStore.GetMemory(Size: Cardinal): Pointer;

var
  MemoryBlockPointer: Pointer;

begin

  if (Self.MemoryBlockList.Count = 0) or (Size > (Self.MemoryBlockSize - Self.PositionInCurrentMemoryBlock)) then begin

    MemoryBlockPointer := TMemoryManager.GetMemory(Self.MemoryBlockSize);

    Self.MemoryBlockList.Add(MemoryBlockPointer);

    Result := MemoryBlockPointer;

    Self.PositionInCurrentMemoryBlock := Size;

  end else begin

    Result := Pointer(Cardinal(Self.MemoryBlockList.Last) + Self.PositionInCurrentMemoryBlock);

    Inc(Self.PositionInCurrentMemoryBlock, Size);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TType1MemoryStore.FreeMemory(Address: Pointer);

begin

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TType1MemoryStore.Destroy;

var
  i: Integer;

begin

  if (Self.MemoryBlockList.Count > 0) then begin

    for i := 0 to (Self.MemoryBlockList.Count - 1) do begin

      TMemoryManager.FreeMemory(Self.MemoryBlockList[i], Self.MemoryBlockSize);

    end;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TType2MemoryStore.Create(MemoryBlockSize: Cardinal; AllocationBlockSize: Cardinal);

begin

  Self.MemoryBlockSize := MemoryBlockSize;

  Self.MemoryBlockList := TList.Create;

  Self.AllocationBlockSize := AllocationBlockSize;

  Self.AllocationBlockList := TQueue.Create;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TType2MemoryStore.GetMemory(Size: Cardinal): Pointer;

var
  MemoryBlockPointer: Pointer;

begin

  if (Self.AllocationBlockList.Count > 0) then begin

    Result := Self.AllocationBlockList.Pop; Exit;

  end;

  if (Self.MemoryBlockList.Count = 0) or (Self.AllocationBlockSize > (Self.MemoryBlockSize - Self.PositionInCurrentMemoryBlock)) then begin

    MemoryBlockPointer := TMemoryManager.GetMemory(Self.MemoryBlockSize);

    Self.MemoryBlockList.Add(MemoryBlockPointer);

    Result := MemoryBlockPointer;

    Self.PositionInCurrentMemoryBlock := Self.AllocationBlockSize;

  end else begin

    Result := Pointer(Cardinal(Self.MemoryBlockList.Last) + Self.PositionInCurrentMemoryBlock);

    Inc(Self.PositionInCurrentMemoryBlock, Self.AllocationBlockSize);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TType2MemoryStore.FreeMemory(Address: Pointer);

begin

  Self.AllocationBlockList.Push(Address);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TType2MemoryStore.Destroy;

var
  i: Integer;

begin

  if (Self.MemoryBlockList.Count > 0) then begin

    for i := 0 to (Self.MemoryBlockList.Count - 1) do begin

      TMemoryManager.FreeMemory(Self.MemoryBlockList[i], Self.MemoryBlockSize);

    end;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.
