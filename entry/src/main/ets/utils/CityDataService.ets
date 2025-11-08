import { CityModel } from '../model/CityModel';

/**
 * 城市数据接口
 */
interface CityData {
  city: string;
  province: string;
  lng: string;
  lat: string;
}

/**
 * 城市数据服务
 * 提供中国城市的经纬度数据
 */
export class CityDataService {
  private static cities: CityModel[] = [];

  /**
   * 初始化城市数据（部分热门城市）
   */
  static initCities(): void {
    if (CityDataService.cities.length > 0) {
      return;
    }

    // 添加热门城市数据
    const cityData: CityData[] = [
      { city: "市辖区", province: "北京市", lng: "116.4133836971231", lat: "39.910924547299565" },
      { city: "市辖区", province: "上海市", lng: "121.48053886017651", lat: "31.235929042252014" },
      { city: "市辖区", province: "天津市", lng: "117.2095232146708", lat: "39.093667843403956" },
      { city: "市辖区", province: "重庆市", lng: "106.55843415537664", lat: "29.568996245338923" },
      { city: "南京市", province: "江苏省", lng: "118.80242172124585", lat: "32.06465288561847" },
      { city: "苏州市", province: "江苏省", lng: "120.59241222959322", lat: "31.303564074441766" },
      { city: "无锡市", province: "江苏省", lng: "120.31858328810601", lat: "31.498809732685714" },
      { city: "杭州市", province: "浙江省", lng: "120.21551180372168", lat: "30.25308298169347" },
      { city: "宁波市", province: "浙江省", lng: "121.62857249434141", lat: "29.866033045866054" },
      { city: "广州市", province: "广东省", lng: "113.27143134445974", lat: "23.135336306695006" },
      { city: "深圳市", province: "广东省", lng: "114.06455183658751", lat: "22.548456637984177" },
      { city: "成都市", province: "四川省", lng: "104.08153351042463", lat: "30.655821878416408" },
      { city: "武汉市", province: "湖北省", lng: "114.31158155473231", lat: "30.598466736400987" },
      { city: "西安市", province: "陕西省", lng: "108.94646555063274", lat: "34.34726881662395" },
      { city: "郑州市", province: "河南省", lng: "113.63141920733915", lat: "34.75343885045448" },
      { city: "济南市", province: "山东省", lng: "117.12639941261048", lat: "36.65655420178723" },
      { city: "青岛市", province: "山东省", lng: "120.38945519114627", lat: "36.072227496663224" },
      { city: "长沙市", province: "湖南省", lng: "112.94547319535287", lat: "28.23488939994364" },
      { city: "合肥市", province: "安徽省", lng: "117.23344266497664", lat: "31.826577833686887" },
      { city: "南昌市", province: "江西省", lng: "115.86458944231661", lat: "28.68945529506072" },
      { city: "福州市", province: "福建省", lng: "119.30346983854001", lat: "26.080429420698078" },
      { city: "厦门市", province: "福建省", lng: "118.09643549976651", lat: "24.485406605176305" },
      { city: "昆明市", province: "云南省", lng: "102.85244836500482", lat: "24.873998150044006" },
      { city: "贵阳市", province: "贵州省", lng: "106.63657676352776", lat: "26.653324822309752" },
      { city: "兰州市", province: "甘肃省", lng: "103.84052119633628", lat: "36.067234693545565" },
      { city: "西宁市", province: "青海省", lng: "101.78445017050855", lat: "36.62338469651661" },
      { city: "石家庄市", province: "河北省", lng: "114.46902163264978", lat: "38.052097109846855" },
      { city: "太原市", province: "山西省", lng: "112.55639149167204", lat: "37.87698902884778" },
      { city: "沈阳市", province: "辽宁省", lng: "123.47109664482264", lat: "41.68383006919066" },
      { city: "大连市", province: "辽宁省", lng: "121.62163148459285", lat: "38.9189536667856" },
      { city: "长春市", province: "吉林省", lng: "125.3306020759069", lat: "43.82195350104314" },
      { city: "哈尔滨市", province: "黑龙江省", lng: "126.54161509031663", lat: "45.808825827952184" },
      { city: "南宁市", province: "广西壮族自治区", lng: "108.37345082581861", lat: "22.822606601187154" },
      { city: "海口市", province: "海南省", lng: "110.32552547126409", lat: "20.04404943925674" },
      { city: "三亚市", province: "海南省", lng: "109.51855670139908", lat: "18.258736291747855" },
      { city: "拉萨市", province: "西藏自治区", lng: "91.12082391546393", lat: "29.65004027476773" },
      { city: "银川市", province: "宁夏回族自治区", lng: "106.23849358740017", lat: "38.492460055509596" },
      { city: "乌鲁木齐市", province: "新疆维吾尔自治区", lng: "87.62443993536046", lat: "43.830763204290484" },
      { city: "呼和浩特市", province: "内蒙古自治区", lng: "111.75550856170946", lat: "40.84842299711348" },
    ];

    CityDataService.cities = cityData.map((data: CityData) => {
      const city = new CityModel();
      city.city = data.city;
      city.province = data.province;
      city.country = "中国";
      city.lng = data.lng;
      city.lat = data.lat;
      return city;
    });
  }

  /**
   * 获取所有城市
   */
  static getAllCities(): CityModel[] {
    CityDataService.initCities();
    return CityDataService.cities;
  }

  /**
   * 根据省份筛选城市
   */
  static getCitiesByProvince(province: string): CityModel[] {
    CityDataService.initCities();
    return CityDataService.cities.filter((c: CityModel) => c.province === province);
  }

  /**
   * 获取所有省份
   */
  static getAllProvinces(): string[] {
    CityDataService.initCities();
    const provinces = new Set<string>();
    CityDataService.cities.forEach((c: CityModel) => provinces.add(c.province));
    return Array.from(provinces).sort();
  }

  /**
   * 根据城市名称查找
   */
  static findCity(cityName: string): CityModel | null {
    CityDataService.initCities();
    const found = CityDataService.cities.find((c: CityModel) => c.city === cityName);
    return found ? found : null;
  }
}
