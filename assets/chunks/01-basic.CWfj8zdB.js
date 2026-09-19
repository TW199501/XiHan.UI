import{j as e}from"./jsx-runtime.BjG_zV1W.js";import{X as t,a as i,b as r,c as o,d as a,e as n}from"./code-view.BLarJwAL.js";import"./jsx-runtime.Dw0sbWRO.js";import"./theme.CJjSsKhw.js";import"./framework.DkvuVDKz.js";import"./config.BGKeu67s.js";import"./index.CVfUds7h.js";import"./slot-content.DPoKlr88.js";import"./react-id.DU3ws1HL.js";const s=`export function createTicker(intervalTime: number) {
  let handle = 0
  return {
    start(onTick: () => void) {
      handle = setInterval(onTick, intervalTime)
    },
    stop() {
      clearInterval(handle)
    },
  }
}`;function C(){return e.jsxs(t,{code:s,lang:"typescript",filename:"ticker.ts",complete:!0,style:{inlineSize:"100%"},children:[e.jsxs(i,{children:[e.jsx(r,{}),e.jsx(o,{})]}),e.jsx(a,{children:e.jsx(n,{})})]})}export{C as default};
