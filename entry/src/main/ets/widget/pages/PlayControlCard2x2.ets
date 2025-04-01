import ActionUtils from '../model/ActionUtils';
import { CollectAction, PlayActionType } from '../model/FormCardConstant';

const SingerAlignRules: Record<string, Record<string, string | VerticalAlign | HorizontalAlign>> = {
  'top': { 'anchor': 'musicTitle', 'align': VerticalAlign.Bottom },
  'left': { 'anchor': 'musicCover', 'align': HorizontalAlign.End }
};

const CollectAlignRules: Record<string, Record<string, string | VerticalAlign | HorizontalAlign>> = {
  'top': { 'anchor': '__container__', 'align': VerticalAlign.Top },
  'right': { 'anchor': '__container__', 'align': HorizontalAlign.End }
};

const CoverAlignRules: Record<string, Record<string, string | VerticalAlign | HorizontalAlign>> = {
  'bottom': { 'anchor': '__container__', 'align': VerticalAlign.Bottom }
};

const PlayAlignRules: Record<string, Record<string, string | VerticalAlign | HorizontalAlign>> = {
  'bottom': { 'anchor': '__container__', 'align': VerticalAlign.Bottom },
  'right': { 'anchor': '__container__', 'align': HorizontalAlign.End }
};

let storageUpdateCall = new LocalStorage();

@Entry(storageUpdateCall)
@Component
struct PlayControlCard2x2 {
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
      Text(this.title)
        .fontSize(14)
        .fontWeight(700)
        .width('85%')
        .fontColor(Color.White)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .maxLines(1)
        .id('musicTitle')
        .textOverflow({overflow: TextOverflow.Ellipsis})
        .width(100)

      Text(this.singer)
        .fontSize(12)
        .fontColor('#99FFFFFF')
        .fontWeight(500)
        .maxLines(1)
        .alignRules(SingerAlignRules)
        .margin({ top: 2 })
        .id('singerText')
        .textOverflow({overflow: TextOverflow.Ellipsis})
        .width(100)

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

      Image(this.loaded ? 'memory://' + this.imgName: $r('app.media.icon'))
        .height(78)
        .width(78)
        .borderRadius(8)
        .alignRules(CoverAlignRules)

      SymbolGlyph(this.isPlay ? $r('sys.symbol.pause_round_triangle_fill') : $r('sys.symbol.play_round_triangle_fill'))
        .fontSize(36)
        .symbolEffect(new ReplaceSymbolEffect(EffectScope.WHOLE), true)
        .fontColor(['#E5FFFFFF'])
        .alignRules(PlayAlignRules)
        .onClick(() => {
          if (this.isPlay) {
            ActionUtils.playByAction(this, PlayActionType.PAUSE, this.formId);
          } else {
            ActionUtils.playByAction(this, PlayActionType.PLAY, this.formId);
          }
        })
    }
    .height('100%')
    .width('100%')
    .linearGradient({
      direction: GradientDirection.Bottom,
      repeating: false,
      colors: this.imageColorHex.length === 6 ? [[`#ff${this.imageColorHex}`, 0.0], [`#cc${this.imageColorHex}`, 0.5], [`#ff${this.imageColorHex}`, 1.0]] : [[`#ff18191d`, 0.0], [`#cc18191d`, 0.5], [`#ff18191d`, 1.0]]
    })
    .padding(12)
    .onClick(() => {
      ActionUtils.jumpPlayPage(this);
    })
  }
}