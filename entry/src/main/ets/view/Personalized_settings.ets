import { PreferencesCache } from "../util/PreferenceCache";
import {HorizontalMode}from '../util/HorizontalCheck'

@Component
export struct Personalized_settings{
  @Consume('NavPathStack') pageStack: NavPathStack;
  @State HorizontalMode_ctrl:string =  PreferencesCache.getUserPreference('HorizontalMode_ctrl','0')
  @Builder
  HorizontalMode_Ctrl(){
    Column(){
      Row(){
        Text('受控制中心的旋转开关控制')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
        Blank()
          .layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.HorizontalMode_ctrl==='1'?true:false})
          .switchPointColor($r('app.color.icon_normal'))
          .selectedColor($r('app.color.back_button_normal'))
          .onChange((isOn: boolean) => {
            if (isOn) {
              this.HorizontalMode_ctrl ='1'
              HorizontalMode(this.HorizontalMode_ctrl==='1')
              PreferencesCache.setUserPreference('HorizontalMode_ctrl', this.HorizontalMode_ctrl)
            }else {
              this.HorizontalMode_ctrl ='0'
              HorizontalMode(this.HorizontalMode_ctrl==='1')
              PreferencesCache.setUserPreference('HorizontalMode_ctrl', this.HorizontalMode_ctrl)
            }
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

    }
    .padding(16)
    .backgroundColor($r('app.color.card_background_two'))
    .borderRadius(12)
    .alignItems(HorizontalAlign.Start)
  }

  build() {
    NavDestination(){
      Column(){
        Scroll(){
          this.HorizontalMode_Ctrl()
        }
      }.padding(16)
    }.title('个性化设置').hideToolBar(true)

  }
}