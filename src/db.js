import{saveOwnerRow,removeOwnerRow}from'./ownerWrites.js';
import{createOwnerLoader}from'./ownerLoader.js';
export{ownerTables,sourceTables}from'./ownerLoader.js';
import{createClient}from'@supabase/supabase-js';
export const supabase=import.meta.env.VITE_SUPABASE_URL&&import.meta.env.VITE_SUPABASE_ANON_KEY?createClient(import.meta.env.VITE_SUPABASE_URL,import.meta.env.VITE_SUPABASE_ANON_KEY,{auth:{storageKey:'adsy-owner-auth'}}):null;
export const loadOwner=(signal,onProgress)=>createOwnerLoader(supabase)(signal,onProgress);
export const save=(table,row,exists)=>saveOwnerRow(supabase,table,row,exists);
export const remove=(table,id)=>removeOwnerRow(supabase,table,id);
