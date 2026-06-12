const grpc = require('@grpc/grpc-js');
const protoLoader = require('@grpc/proto-loader');
const path = require('path');

const PROTO_PATH = path.join(__dirname, '..', 'proto', 'calc.proto');

const packageDef = protoLoader.loadSync(PROTO_PATH, {
  keepCase: true,
  longs: String,
  enums: String,
  defaults: true,
  oneofs: true,
});

const calcProto = grpc.loadPackageDefinition(packageDef).calc;

function power(call, callback) {
  callback(null, { result: Math.pow(call.request.a, call.request.b) });
}

function squareRoot(call, callback) {
  if (call.request.a < 0) {
    callback(null, { error: 'cannot take square root of negative number' });
    return;
  }
  callback(null, { result: Math.sqrt(call.request.a) });
}

function factorial(call, callback) {
  const n = Math.round(call.request.a);
  if (n < 0) {
    callback(null, { error: 'factorial of negative number is undefined' });
    return;
  }
  let result = 1;
  for (let i = 2; i <= n; i++) result *= i;
  callback(null, { result });
}

function log(call, callback) {
  if (call.request.a <= 0 || call.request.b <= 0 || call.request.b === 1) {
    callback(null, { error: 'invalid arguments for logarithm' });
    return;
  }
  callback(null, { result: Math.log(call.request.a) / Math.log(call.request.b) });
}

const server = new grpc.Server();
server.addService(calcProto.AdvancedService.service, {
  Power: power,
  SquareRoot: squareRoot,
  Factorial: factorial,
  Log: log,
});

server.bindAsync('[::]:50052', grpc.ServerCredentials.createInsecure(), () => {
  console.log('[service-b] running on port 50052');
});
