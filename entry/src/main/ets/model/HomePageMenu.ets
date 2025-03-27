export class HomePageMenu {
  title: ResourceStr;
  path: string;

  constructor(title: ResourceStr, path: string) {
    this.title = title;
    this.path = path;
  }
}


export class HomePageTitleMenu {
  icon: Resource;
  action: () => void;

  constructor(icon: Resource, action: () => void) {
    this.icon = icon;
    this.action = action;
  }
}