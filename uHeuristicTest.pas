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
  TRoutePath = class;

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
    function    GetClientsLength: integer;
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

  TRoute = class(TObject)
  private
    fDeposit       : TDeposit;
    fVehicles      : TVehicles;
    fClients       : TClients;
    fTotalCost     : real;
    fTotalDistance : real;
    fTotalVehicles : integer;
    fTotalClients  : integer;
    fInitialRoute  : TRoutePath;
  public
    constructor Create;
    destructor  Destroy; override;
    function    CalcTotalCost: real;
    function    CalcTotalDistance: real;
    function    GetTotalVehicles: integer;
    function    GetTotalClients: integer;
    function    GenInitialRoute: TList;
  published
    property Deposit       : TDeposit   read fDeposit;
    property Vehicles      : TVehicles  read fVehicles;
    property Clients       : TClients   read fClients;
    property TotalCost     : real       read fTotalCost;
    property TotalDistance : real       read fTotalDistance;
    property TotalVehicles : integer    read fTotalVehicles;
    property TotalClients  : integer    read fTotalClients;
    property InitialRoute  : TRoutePath read InitialRoute;
  end;

  TRoutePath = class(TClients)
  public
    constructor Create; reintroduce;
    function Add(client: TClient): integer; reintroduce;
    procedure Swap(i, j: integer);
    procedure Reverse(i, j: integer);
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
  TClient(inherited Insert(0, deposit));
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

function TDeposit.GetClientsLength: integer;
begin
  Result := fClients.Count;
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

{ TRoute }
constructor TRoute.Create;
begin
  fClients:=TClients.Create(true);
  fVehicles:=TVehicles.Create(true);
  fInitialRoute:=TRoutePath.Create;
end;

destructor TRoute.Destroy;
begin
  fClients.Free;
  fVehicles.Free;
  fInitialRoute.Free;
  inherited;
end;

function TRoute.CalcTotalCost: real;
var
  totalCost: real;
  i: integer;
begin
  totalCost:=0.0;
  for i:=0 to fVehicles.Count -1 do
  begin
    totalCost:=totalCost + fVehicles[i].CostPerKm;
  end;
  totalCost:=totalCost * fTotalDistance;
  Result:=totalCost;
end;

function TRoute.CalcTotalDistance: real;
var
  totalDist: real;
  i: integer;
begin
  totalDist:=0.0;
  for i:=1 to fClients.Count - 1 do
  begin
    totalDist:=totalDist + CalcEuclideanDistance(fClients[0], fClients[i]);
  end;
  Result:=totalDist;
end;

function TRoute.GetTotalVehicles: integer;
begin
  Result:=fVehicles.Count;
end;

function TRoute.GetTotalClients: integer;
begin
  Result:=fClients.Count;
end;

function TRoute.GenInitialRoute: TRoutePath;
var
  i: integer;
  deposit, current, nextClient, bestClient: TClient;
  distance, bestDistance: real;
  pool: TList;
begin
  fInitialRoute.Free;
  deposit:=fDeposit;
  fInitialRoute.InsertDeposit(deposit);
  pool:= TList.Create;
  try
    for i:=0 to fClients.Count - 1 do
      pool.Add(fClients[i]);
    bestDistance:=-1;
    bestClient:=-1;
    for i:=0 to pool.Count - 1 do
    begin
      distance:=CalcEuclideanDistance(deposit, fClient(pool[i]));
      if distance > bestDistance then
      begin
        bestDistance:=distance;
        bestClient:=fClient(pool[i]);
      end;
    end;
    if bestClient <> nil then
    begin
      fInitialRoute.Add(bestClient);
      pool.Remove(bestClient);
    end;
    while pool.Count > 0 do
    begin
      current:=fInitialRoute[fInitialRoute.Count - 1];
      bestDistance:=INFINITE;
      bestClient:=nil;
      for i := 0 to pool.Count - 1 do
      begin
        dist := CalcEuclideanDistance(current, TClient(pool[i]));
        if dist < bestDist then
        begin
          bestDist := dist;
          bestClient := TClient(pool[i]);
        end;
      end;
      fInitialRoute.Add(bestClient);
      pool.Remove(bestClient);
    end;
    fInitialRoute.Add(best);
  finally
    pool.Free;
  end;
  Result:=fInitialRoute;
end;

{ TRoutePath }

constructor TRoutePath.Create;
begin
  inherited Create(false);
end;

function TRoutePath.Add(client: TClient): integer;
begin
  Result:= inherited Add(client);
end;

procedure TRoutePath.Swap(i, j: integer);
var
  tmp: TClient;
begin
  tmp:=Items[i];
  Items[i]:=Items[j];
  Items[j]:=tmp;
end;

procedure TRoutePath.Reverse(i, j: integer);
begin
  while i<j do
  begin
    Swap(i,j);
    Inc(i); Dec(j);
  end;
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
