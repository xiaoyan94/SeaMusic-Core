import ActionUtils from '../model/ActionUtils';
import { CollectAction, PlayActionType } from '../model/FormCardConstant';

let storageUpdateCall = new LocalStorage();

@Entry(storageUpdateCall)
@Component
struct PlayControlCard1x2 {
  @LocalStorageProp('formId') formId: string = '';
  @LocalStorageProp('isPlay') isPlay: boolean = false;
  @LocalStorageProp('title') title: string = '当前歌曲';
  @LocalStorageProp('isCollected') isCollected: boolean = false;
  @LocalStorageProp('imgName') imgName: ResourceStr = $r('app.media.icon');
  @LocalStorageProp('singer') singer: string = '歌手';
  @LocalStorageProp('songId') songId: string = '';
  @LocalStorageProp('isNeedRequestUpdate') @Watch('requestData') isNeedRequestUpdate: boolean = false;
  @LocalStorageProp('imageColor') imageColor: string = 'rgba(76, 72, 68, 1)';
  @LocalStorageProp('imageColorHex') imageColorHex: string = '18191d';
  @LocalStorageProp('loaded') loaded: boolean = false;

  requestData() {
    ActionUtils.updateControlCardAction(this, this.formId);
  }

  build() {
    Row() {
      Image(this.loaded ? 'memory://' + this.imgName: $r('app.media.icon'))
        .height('100%')
        .borderRadius(8)
        .margin({ top: 2 })

      SymbolGlyph(this.isPlay ? $r('sys.symbol.pause_round_triangle_fill') : $r('sys.symbol.play_round_triangle_fill'))
        .fontSize(28)
        .symbolEffect(new ReplaceSymbolEffect(EffectScope.WHOLE), true)
        .fontColor(['#E5FFFFFF'])
        .onClick(() => {
          if (this.isPlay) {
            ActionUtils.playByAction(this, PlayActionType.PAUSE, this.formId);
          } else {
            ActionUtils.playByAction(this, PlayActionType.PLAY, this.formId);
          }
        })

      SymbolGlyph($r('sys.symbol.forward_end_fill'))
        .fontSize(28)
        .fontColor(['#E5FFFFFF'])
        .onClick(() => {
          ActionUtils.playByAction(this, PlayActionType.NEXT, this.formId);
        })
    }
    .height('100%')
    .width('100%')
    .linearGradient({
      direction: GradientDirection.Bottom,
      repeating: false,
      colors: [[`#ff${this.imageColorHex}`, 0.0], [`#cc${this.imageColorHex}`, 0.5], [`#ff${this.imageColorHex}`, 1.0]]
    })
    .justifyContent(FlexAlign.SpaceBetween)
    .padding(8)
    .onClick(() => {
      ActionUtils.jumpPlayPage(this);
    })
  }
}