import{j as e}from"./jsx-runtime.BjG_zV1W.js";import{c as t}from"./index.Bj9YYS_y.js";import{X as n,d as o,e as m}from"./code-view.BLarJwAL.js";import{X as i,a}from"./markdown-stream.iJW4rUCy.js";import"./jsx-runtime.Dw0sbWRO.js";import"./theme.CJjSsKhw.js";import"./framework.DkvuVDKz.js";import"./config.BGKeu67s.js";import"./index.CVfUds7h.js";import"./slot-content.DPoKlr88.js";import"./react-id.DU3ws1HL.js";const s=`先看这段实现：

\`\`\`typescript
export function clamp(n: number, min: number, max: number) {
  return Math.min(Math.max(n, min), max)
}
\`\`\`

两端都夹住，越界的输入不会漏过去。
`,d=t(),p=d.render(s,{ended:!0});function S(){return e.jsx(i,{blocks:p,style:{inlineSize:"100%"},children:e.jsx(a,{children:({block:r})=>r.kind==="code"?e.jsx(n,{code:r.source??"",lang:r.lang,complete:r.complete,lineNumbers:!0,children:e.jsx(o,{children:e.jsx(m,{})})}):e.jsx("div",{dangerouslySetInnerHTML:{__html:r.html}})})})}export{S as default};
