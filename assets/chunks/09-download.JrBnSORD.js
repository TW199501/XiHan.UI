import{j as r}from"./jsx-runtime.BjG_zV1W.js";import{D as t}from"./index.DfnbpvFp.js";import{X as i,a as s,b as a,d as m,e as n}from"./code-view.EhHenrO5.js";import{X as p}from"./download-trigger.C2OpBs6Z.js";import{X as l}from"./icon.BAofDLCd.js";import"./normalize-props.B0unPZ8W.js";import"./theme.DB2McjZw.js";import"./framework.D1FqHTxE.js";import"./config.CyJHTnU4.js";import"./index.Cgwy3NI6.js";import"./slot-content.BDi8aYdV.js";import"./react-id.PWnPtOkW.js";import"./use-machine.BcKhQhn1.js";import"./index.DEmbwZee.js";const e="retry.ts",o=`export async function retry<T>(run: () => Promise<T>, times = 3): Promise<T> {
  let last: unknown
  for (let i = 0; i < times; i++) {
    try {
      return await run()
    }
    catch (error) {
      last = error
    }
  }
  throw last
}`;function T(){return r.jsxs(i,{code:o,lang:"typescript",filename:e,complete:!0,style:{inlineSize:"100%"},children:[r.jsxs(s,{children:[r.jsx(a,{}),r.jsxs(p,{data:o,fileName:e,variant:"ghost",size:"sm",children:[r.jsx(l,{icon:t})," ","下载"]})]}),r.jsx(m,{children:r.jsx(n,{})})]})}export{T as default};
