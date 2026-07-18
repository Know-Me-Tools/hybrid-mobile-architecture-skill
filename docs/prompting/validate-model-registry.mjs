import {readFile} from 'node:fs/promises';
import {parse} from 'yaml';
const registry=parse(await readFile(new URL('./model-registry.yaml', import.meta.url),'utf8'));
const errors=[];
for(const [index,model] of registry.models.entries()){
  for(const field of ['provider','model_id','model_family','verified_at','official_sources','recommended_roles','known_constraints','availability']) if(model[field]===undefined) errors.push(`${index}:${field}`);
  if(!Array.isArray(model.official_sources)||!model.official_sources.length||model.official_sources.some(url=>!/^https:\/\//.test(url))) errors.push(`${index}:official_sources`);
}
if(errors.length){console.error(errors.join('\n'));process.exit(1)}
console.log(`validated ${registry.models.length} model entries`);
