class SiteListModel {
  String? message;
  int? count;
  int? page;
  int? pageSize;
  int? numPages;
  String? next;
  Null previous;
  List<Sites>? sites;

  SiteListModel({
    this.message,
    this.count,
    this.page,
    this.pageSize,
    this.numPages,
    this.next,
    this.previous,
    this.sites,
  });

  SiteListModel.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    count = json['count'];
    page = json['page'];
    pageSize = json['page_size'];
    numPages = json['num_pages'];
    next = json['next'];
    previous = json['previous'];
    if (json['sites'] != null) {
      sites = <Sites>[];
      json['sites'].forEach((v) {
        sites!.add(Sites.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['message'] = message;
    data['count'] = count;
    data['page'] = page;
    data['page_size'] = pageSize;
    data['num_pages'] = numPages;
    data['next'] = next;
    data['previous'] = previous;
    if (sites != null) {
      data['sites'] = sites!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Sites {
  String? siteCode;
  String? name;
  String? address;

  Sites({this.siteCode, this.name, this.address});

  Sites.fromJson(Map<String, dynamic> json) {
    siteCode = json['site_code'];
    name = json['name'];
    address = json['address'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['site_code'] = siteCode;
    data['name'] = name;
    data['address'] = address;
    return data;
  }
}
