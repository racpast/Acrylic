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
      constructor Create(MemoryBlockSize: Integer);
      destructor Destroy; override;
    public
      function GetMemory(Size: Integer): Pointer;
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
  // If there is not enough space inside an already existing memory block...
  if (Self.MemoryBlockList.Count = 0) or (Size > Self.MemoryBlockSize - Self.PositionInCurrentMemoryBlock) then begin

    // We have to allocate a new one
    TMemoryManager.GetMemory(MemoryBlockPointer, Self.MemoryBlockSize); Self.MemoryBlockList.Add(MemoryBlockPointer); Self.PositionInCurrentMemoryBlock := 0;

  end;

  // A pointer inside the memory block is returned and the position is advanced
  Result := Pointer(Integer(Self.MemoryBlockList.Last) + Self.PositionInCurrentMemoryBlock); Inc(Self.PositionInCurrentMemoryBlock, Size);
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.
