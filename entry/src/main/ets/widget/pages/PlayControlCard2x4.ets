import ActionUtils from '../model/ActionUtils';
import { CollectAction, PlayActionType } from '../model/FormCardConstant';

const CollectAlignRules: Record<string, Record<string, string | VerticalAlign | HorizontalAlign>> = {
  'top': { 'anchor': '__container__', 'align': VerticalAlign.Top },
  'right': { 'anchor': '__container__', 'align': HorizontalAlign.End }
};

const TitleAlignRules: Record<string, Record<string, string | VerticalAlign | HorizontalAlign>> = {
  'left': { 'anchor': 'musicCover', 'align': HorizontalAlign.End }
};

const SingerAlignRules: Record<string, Record<string, string | VerticalAlign | HorizontalAlign>> = {
  'top': { 'anchor': 'musicTitle', 'align': VerticalAlign.Bottom },
  'left': { 'anchor': 'musicCover', 'align': HorizontalAlign.End }
};

const ControlAlignRules: Record<string, Record<string, string | VerticalAlign | HorizontalAlign>> = {
  'bottom': { 'anchor': '__container__', 'align': VerticalAlign.Bottom },
  'left': { 'anchor': 'musicCover', 'align': HorizontalAlign.End }
};

let storageUpdateCall = new LocalStorage();

@Entry(storageUpdateCall)
@Component
struct PlayControlCard2x4 {
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
    RelativeContainer() {
      Image(this.loaded ? 'memory://' + this.imgName: $r('app.media.icon'))
        .height('100%')
        .borderRadius(10)
        .aspectRatio(1)
        .id('musicCover')
        .onClick(() => {
          ActionUtils.jumpPlayPage(this);
        })

      SymbolGlyph(this.isCollected ? $r('sys.symbol.heart_fill') : $r('sys.symbol.heart'))
        .fontSize(24)
        .symbolEffect(new ReplaceSymbolEffect(EffectScope.WHOLE), true)
        .fontColor(['#E5FFFFFF'])
        .alignRules(CollectAlignRules)
        .onClick(() => {
          if (this.isCollected) {
            ActionUtils.collectAction(this, CollectAction.UNCOLLECTED, this.formId, this.songId);
          } else {
            ActionUtils.collectAction(this, CollectAction.COLLECTED, this.formId, this.songId);
          }
        })

      Text(this.title)
        .fontSize(16)
        .fontWeight(700)
        .fontColor(Color.White)
        .maxLines(1)
        .margin({
          top: 30,
          left: 24
        })
        .alignRules(TitleAlignRules)
        .id('musicTitle')
        .textOverflow({overflow: TextOverflow.Ellipsis})
        .width(150)

      Text(this.singer)
        .fontSize(14)
        .fontColor(Color.White)
        .fontWeight(500)
        .opacity(0.6)
        .maxLines(1)
        .alignSelf(ItemAlign.Start)
        .margin({
          top: 5,
          left: 24
        })
        .alignRules(SingerAlignRules)
        .textOverflow({overflow: TextOverflow.Ellipsis})
        .width(150)

      Row() {
        SymbolGlyph($r('sys.symbol.backward_end_fill'))
          .fontSize(24)
          .fontColor(['#E5FFFFFF'])
          .onClick(() => {
            ActionUtils.playByAction(this, PlayActionType.PREVIOUS, this.formId);
          })

        SymbolGlyph(this.isPlay ? $r('sys.symbol.pause') : $r('sys.symbol.play_fill'))
          .fontSize(24)
          .symbolEffect(new ReplaceSymbolEffect(EffectScope.WHOLE), true)
          .fontColor(['#E5FFFFFF'])
          .margin({
            left: 25,
            right: 25
          })
          .onClick(() => {
            if (this.isPlay) {
              ActionUtils.playByAction(this, PlayActionType.PAUSE, this.formId);
            } else {
              ActionUtils.playByAction(this, PlayActionType.PLAY, this.formId);
            }
          })

        SymbolGlyph($r('sys.symbol.forward_end_fill'))
          .fontSize(24)
          .fontColor(['#E5FFFFFF'])
          .onClick(() => {
            ActionUtils.playByAction(this, PlayActionType.NEXT, this.formId);
          })
      }
      .height(30)
      .margin({ left: 24 })
      .justifyContent(FlexAlign.SpaceBetween)
      .alignRules(ControlAlignRules)
    }
    .height('100%')
    .width('100%')
    .padding(12)
    .onClick(() => {
      ActionUtils.jumpPlayPage(this);
    })
    .linearGradient({
      direction: GradientDirection.Bottom,
      repeating: false,
      colors: this.imageColorHex.length === 6 ? [[`#ff${this.imageColorHex}`, 0.0], [`#cc${this.imageColorHex}`, 0.5], [`#ff${this.imageColorHex}`, 1.0]] : [[`#ff18191d`, 0.0], [`#cc18191d`, 0.5], [`#ff18191d`, 1.0]]
    })
  }
}