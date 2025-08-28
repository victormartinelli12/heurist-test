unit uHeuristicTest;

interface

uses
  SysUtils,
  Classes,
  Contnrs,
  Math;

type
  TClient = class(TObject)
  protected
    fX: real;
    fY: real;
    constructor Create(x, y, demand: real; clientType: integer);
  private
    fName         : string;
    fDemand       : real;
    fDemandWeight : real
    fClientType   : integer;
  public
    procedure SetDemand(demand: real);
    function  ToString: string;
  published
    property X          : real    read fX;
    property Y          : real    read fY;
    property Name       : string  read fName;
    property Demand     : real    read fDemand;
    property ClientType : integer read fClientType;
  end;

  TClients = class(TObjectList)
  private
    function  GetItem(index: integer): TClient;
    procedure SetItem(index: integer; const client: TClient);
  public
    function  Add(aClient: TClient): integer;
    procedure InsertDeposit(deposit: TDeposit);

    property Items[index: integer]: TClient read GetItem write SetItem; default;
  end;

  TVechile = class(TObject)
  private
    fCapacity      : real;
    fDepartureTime : TDateTime;
    fArriveTime    : TDateTime;
    fCostPerKm     : real;
    fClients       : TClients;
    fCanLoad       : boolean;
    fWeigthLimit   : real;
  public
    constructor Create(capacity, costPerKm: real);
    destructor  Destroy; override;
    procedure   SetCapacityVehicle(clientDemand, clientWeigthDemand: real);
    procedure   SetVehicleArriveTime;
  published
    property Capacity      : real      read fCapacity;
    property DepartureTime : TDateTime read fDepartureTime;
    property ArriveTime    : TDateTime read fArriveTime;
    property CostPerKm     : real      read fCostPerKm;
    property Clients       : TClients  read fClients;
    property CanLoad       : boolean   read fCanLoad;
    property WeigthLimit   : real      read fWeigthLimit;
  end;

  TVechiles = class(TObjectList)
  private
    function GetItem(index: integer): TVechile;
  public
    function Add(aVehicle: TVechile): integer;
    property Items[index: integer]: TVechile read GetItem; default;
  end;

  // implementar TDeposit

implementation

{ TClient }
constructor TClient.Create(x, y, demand: real; clientType: integer);
begin
  fX:=x;
  fY:=y;
  fDemand:=demand;
  fClientType:=clientType;
end;

procedure TClient.SetDemand(demand: real);
begin
  fDemand:=fDemand - demand;
end;

function TClient.ToString: string;
var
  sb: TStringBuilder;
begin
  sb:=TStringBuilder.Create;
  try
    sb.Append('Cliente: ' + IntToStr(fClientType) + ' - (');
    sb.Append(FormatFloat('0.00', fX) + ', ' + FormatFloat('0.00', fY) + ')');
    Result:=sb
  finally
    sb.Free;
  end;
end;

{ TClients }
function TClients.GetItem(index: integer): TClient;
begin 
  Result:=TClient(inherited Items[index])
end;

function TClients.SetItem(index: integer; const client: TClient);
begin
  inherited Items[index]:=client;
end;

function  TClients.Add(aClient: TClient): integer;
begin
  Result:=inherited Add(client);
end;

procedure TClients.InsertDeposit(deposit: TDeposit);
begin
  inherited Insert(0, deposit);
end;

{ TVechile }
constructor TVechile.CreateCreate(capacity, costPerKm: real);
begin
  fCapacity:=capacity;
  fCostPerKm:=costPerKm;
  fClients:=TClients.Create(true);
  fCanLoad:=true;
  fDepartureTime:=Now;
end;

destructor TVechile.Destroy;
begin
  fClients.Free;
  inherited;
end;

procedure TVechile.SetCapacityVehicle(clientDemand, clientWeigthDemand: real);
begin
  if (fCapacity > 0) and (fWeigthLimit > 0) then
  begin
    fCapacity:=fCapacity - clientDemand;
    fWeigthLimit:=fWeigthLimit - clientWeigthDemand;
  end
  else
    fCanLoad=false;
end;

procedure TVechile.SetVehicleArriveTime;
begin
  fArriveTime:=Now;
end;

{ TVehicles }
function TVehicles.GetItem(index: integer): TVehicle;
begin
  Result:= inherited Items[index];
end;

function TVechiles.Add(vehicle: TVechile): integer;
begin
  Result:= inherited Add(vehicle)
end;

{ TDeposit }
// implementar TDeposit aqui.

end.
