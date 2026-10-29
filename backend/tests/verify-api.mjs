// Pruebas de integración: ejecutar después de npm run seed y npm run start:dev.
import assert from 'node:assert/strict';
const base = process.env.API_BASE_URL || 'http://localhost:3000/api';
async function req(method,path,token,body){
  const r=await fetch(base+path,{method,headers:{'Content-Type':'application/json',...(token?{Authorization:`Bearer ${token}`}:{})},body:body?JSON.stringify(body):undefined});
  return { status:r.status, data:await r.json() };
}
const login=async(email)=>req('POST','/auth/login',null,{email,password:'DemoVoto#2026!'});
const voter=await login('socio1@example.com'); assert.equal(voter.status,201);
const token=voter.data.accessToken;
const e=await req('GET','/election',token); assert.equal(e.status,200); assert.equal(e.data.candidates.length,3);
const invalid=await req('POST','/votes',token,{candidateId:'00000000-0000-4000-8000-000000000000'}); assert.equal(invalid.status,404);
const resultBefore=await req('GET','/election/results',token); assert.equal(resultBefore.status,403);
const c=e.data.candidates[0].id;
const v1=await req('POST','/votes',token,{candidateId:c}); assert.equal(v1.status,201); assert.ok(v1.data.receipt);
const v2=await req('POST','/votes',token,{candidateId:c}); assert.equal(v2.status,409);
const mine=await req('GET','/votes/me',token); assert.equal(mine.data.receipt,v1.data.receipt);
// Dos solicitudes al mismo tiempo con otra cuenta: una sola debe registrarse.
const voter2=await login('socio2@example.com'); assert.equal(voter2.status,201);
const both=await Promise.all([
  req('POST','/votes',voter2.data.accessToken,{candidateId:c}),
  req('POST','/votes',voter2.data.accessToken,{candidateId:c}),
]);
assert.deepEqual(both.map(x=>x.status).sort(),[201,409]);
const closedByVoter=await req('POST','/election/close',token); assert.equal(closedByVoter.status,403);
const admin=await login('admin@example.com'); assert.equal(admin.status,201);
const done=await req('POST','/election/close',admin.data.accessToken); assert.equal(done.status,201);
const totals=await req('GET','/election/results',token); assert.equal(totals.status,200);
assert.equal(totals.data.results.reduce((n,x)=>n+Number(x.votes),0),2);
const denied=await req('POST','/votes',voter2.data.accessToken,{candidateId:c}); assert.equal(denied.status,403);
console.log('OK: login, candidatura inválida, secreto durante la jornada, voto único, roles, cierre, resultados y bloqueo tras cierre.');
