import { display } from '@kit.ArkUI';

export function playing_md_f(){
  let ret: boolean = false;
  let heng: boolean = true;
  let mode:string = '2';
  ret = display.isFoldable();
  if (ret) {
    let data: display.FoldStatus = display.getFoldStatus();
    mode=JSON.stringify(data)
    console.info('Succeeded in obtaining fold status. Data: ' + JSON.stringify(data));
    if (mode!='2') {
      heng = false
    }
  }else{
    heng =true
  }
    return heng
}