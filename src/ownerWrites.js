const tables=['products','mappings','hpp','targets','notes'];
export async function saveOwnerRow(client,table,row,exists){
 if(!tables.includes(table))throw Error('Tabel tidak diizinkan.');
 const q=exists?client.from('owner_'+table).update(row).eq('id',row.id):client.from('owner_'+table).insert(row);
 const{data,error}=await q.select('*').single();if(error)throw error;if(!data?.id)throw Error('Data tersimpan belum dapat dikonfirmasi.');return data;
}
export async function removeOwnerRow(client,table,id){
 if(!['mappings','targets','notes'].includes(table))throw Error('Data ini tidak dapat dihapus dari aplikasi.');
 const{data,error}=await client.from('owner_'+table).delete().eq('id',id).select('id');if(error)throw error;
 if(!data?.some(r=>r.id===id))throw Error('Data tidak ditemukan atau akses sudah berubah. Muat ulang data.');return id;
}
export function applyOwnerRow(state,table,row){if(!state)return state;return {...state,owner:{...state.owner,[table]:[...state.owner[table].filter(r=>r.id!==row.id),row]}};}
export function dropOwnerRow(state,table,id){if(!state)return state;return {...state,owner:{...state.owner,[table]:state.owner[table].filter(r=>r.id!==id)}};}
export function mergeRefreshedData(next,current,startedVersion,currentVersion){return startedVersion===currentVersion||!current?next:{...next,owner:current.owner};}
