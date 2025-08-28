unit uHeuristicTest;

interface

uses
  SysUtils,
  Classes,
  Contnrs,
  Math;

type
  TClients = class;
  TVehicles = class;
  TVehicle = class;

  TClient = class(TObject)
  protected
    fX    : real;
    fY    : real;
    fName : string;
    constructor Create(x, y, demand: real; clientType: integer);
  private
    fDemand       : real;
    fDemandWeight : real;
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

  TDeposit = class(TClient)
  private
    fCapacity : real;
    fClients  : TClients;
    fVehicles : TVehicles;
  public
    constructor Create(capacity: real);
    destructor  Destroy; override;
    function    FindMostDistantClient: TClient;
    function    FindNearestClient: TClient;
    function    GetClient(index: integer): TClient;
    function    GetVehicle(index: integer): TVehicle;
    procedure   SetDepositCapacity;
    procedure   SortClients;
    property Clients[index: integer]  : TClient  read GetClient;
    property Vehicles[index: integer] : TVehicle read GetVehicle;
  published
    property Name                     : string   read fName;
    property Capacity                 : real     read fCapacity;
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

  TVehicle = class(TObject)
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

  TVehicles = class(TObjectList)
  private
    function GetItem(index: integer): TVehicle;
  public
    function Add(aVehicle: TVehicle): integer;
    property Items[index: integer]: TVehicle read GetItem; default;
  end;

function CompareClientsPointers(ptr1, ptr2: Pointer): longInt;
function CalcEuclideanDistance(deposit, client: TClient): real;

implementation

const
  INFINITE=10E14;

var
  GLOBAL_DEPOSIT: TDeposit;

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
    Result:=sb.ToString;
  finally
    sb.Free;
  end;
end;

{ TClients }
function TClients.GetItem(index: integer): TClient;
begin
  Result:=TClient(inherited Items[index])
end;

procedure TClients.SetItem(index: integer; const client: TClient);
begin
  inherited Items[index]:=client;
end;

function  TClients.Add(aClient: TClient): integer;
begin
  Result:=inherited Add(aClient);
end;

procedure TClients.InsertDeposit(deposit: TDeposit);
begin
  inherited Insert(0, deposit);
end;

{ TVechile }
constructor TVehicle.Create(capacity, costPerKm: real);
begin
  fCapacity:=capacity;
  fCostPerKm:=costPerKm;
  fClients:=TClients.Create(true);
  fCanLoad:=true;
  fDepartureTime:=Now;
end;

destructor TVehicle.Destroy;
begin
  fClients.Free;
  inherited;
end;

procedure TVehicle.SetCapacityVehicle(clientDemand, clientWeigthDemand: real);
begin
  if (fCapacity > 0) and (fWeigthLimit > 0) then
  begin
    fCapacity:=fCapacity - clientDemand;
    fWeigthLimit:=fWeigthLimit - clientWeigthDemand;
  end
  else
    fCanLoad:=false;
end;

procedure TVehicle.SetVehicleArriveTime;
begin
  fArriveTime:=Now;
end;

{ TVehicles }
function TVehicles.GetItem(index: integer): TVehicle;
begin
  Result:= TVehicle(inherited Items[index]);
end;

function TVehicles.Add(aVehicle: TVehicle): integer;
begin
  Result:= inherited Add(aVehicle)
end;

{ TDeposit }
constructor TDeposit.Create(capacity: real);
begin
  inherited Create(0.0,0.0,0.0,-1);
  fName:='Deposito';
  fCapacity:=capacity;
  fClients:=TClients.Create(true);
  fVehicles:=TVehicles.Create(true);
end;

destructor TDeposit.Destroy;
begin
  fClients.Free;
  fVehicles.Free;
  inherited;
end;

function TDeposit.FindMostDistantClient: TClient;
var
  i: integer;
  distance, maxDistance: real;
  client: TClient;
begin
  distance:=0.0;
  for i:= 1 to fClients.Count - 1 do
  begin
    maxDistance:=CalcEuclideanDistance(fClients[0], fClients[i]);
    if maxDistance > distance then
    begin
      distance:=maxDistance;
      client:=fClients[i]
    end;
  end;
  Result:=client;
end;

function TDeposit.FindNearestClient: TClient;
var
  i: integer;
  distance, minDistance: real;
  client: TClient;
begin
  distance:=INFINITE;
  for i:=1 to fClients.Count - 1 do
  begin
    minDistance:=CalcEuclideanDistance(fClients[0], fClients[i]);
    if minDistance < distance then
    begin
      distance:=minDistance;
      client:=fClients[i]
    end;
  end;
  Result:=client;
end;

function TDeposit.GetVehicle(index: integer): TVehicle;
begin
  Result:=fVehicles.GetItem(index);
end;

function TDeposit.GetClient(index: integer): TClient;
begin
  Result:=fClients.GetItem(index);
end;

procedure TDeposit.SetDepositCapacity;
var
  i: integer;
  totalDemand: real;
  client: TClient;
begin
  totalDemand:=0;
  for i:=1 to fClients.Count - 1 do
  begin
    client:=fClients.GetItem(i);
    totalDemand:=totalDemand + client.Demand;
  end;
  if fCapacity > totalDemand then
     fCapacity:=fCapacity - totalDemand;
end;

procedure TDeposit.SortClients;
begin
  GLOBAL_DEPOSIT:=Self;
  fClients.Sort(@CompareClientsPointers);
end;

// FUNÇÕES GLOBAIS -------

function CalcEuclideanDistance(deposit, client: TClient): real;
var
  diffX, diffY: real;
begin
  diffX:=Power(client.X - deposit.X, 2);
  diffY:=Power(client.Y - deposit.Y, 2);
  Result:=Sqrt(diffX + diffY);
end;

function CompareClientsPointers(ptr1, ptr2: Pointer): longInt;
var
  client1, client2: TClient;
  dist1, dist2: real;
begin
  client1:=TClient(ptr1);
  client2:=TClient(ptr2);
  dist1:=CalcEuclideanDistance(GLOBAL_DEPOSIT.fClients[0], client1);
  dist2:=CalcEuclideanDistance(GLOBAL_DEPOSIT.fClients[0], client2);
  if dist1 > dist2 then
    Result:=-1
  else if dist1 < dist2 then
    Result:=1
  else
    Result:=0;
end;

end.
