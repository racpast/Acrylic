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
  Classes, SysUtils;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TMemoryStore = class
    private
      MemoryBlockSize: Integer;
      MemoryBlockList: TList;
      PositionInCurrentMemoryBlock: Integer;
    public
      constructor Create; overload;
      constructor Create(MemoryBlockSize: Integer); overload;
      destructor  Destroy; override;
    public
      function    GetMemory(Size: Integer): Pointer;
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

const
  MEMORY_STORE_DEFAULT_BLOCK_SIZE = 65536;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TMemoryStore.Create;

begin

  Self.MemoryBlockSize := MEMORY_STORE_DEFAULT_BLOCK_SIZE;
  Self.MemoryBlockList := TList.Create;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TMemoryStore.Create(MemoryBlockSize: Integer);

begin

  Self.MemoryBlockSize := MemoryBlockSize;
  Self.MemoryBlockList := TList.Create;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TMemoryStore.Destroy;

var
  i: Integer;

begin

  if (Self.MemoryBlockList.Count > 0) then begin
    for i := 0 to Self.MemoryBlockList.Count - 1 do begin
      TMemoryManager.FreeMemory(Self.MemoryBlockList[i], Self.MemoryBlockSize);
    end;
  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TMemoryStore.GetMemory(Size: Integer): Pointer;

var
  MemoryBlockPointer: Pointer;

begin

  if (Self.MemoryBlockList.Count = 0) or (Size > (Self.MemoryBlockSize - Self.PositionInCurrentMemoryBlock)) then begin

    TMemoryManager.GetMemory(MemoryBlockPointer, Self.MemoryBlockSize); Self.MemoryBlockList.Add(MemoryBlockPointer); Self.PositionInCurrentMemoryBlock := 0;

  end;

  Result := Pointer(Integer(Self.MemoryBlockList.Last) + Self.PositionInCurrentMemoryBlock); Inc(Self.PositionInCurrentMemoryBlock, Size);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.
