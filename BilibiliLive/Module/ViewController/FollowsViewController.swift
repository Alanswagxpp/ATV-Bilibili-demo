//
//  F.swift
//  BilibiliLive
//
//  Created by Etan Chen on 2021/4/4.
//

import Alamofire
import SwiftyJSON
import UIKit

class FollowsViewController: UIViewController, BLTabBarContentVCProtocol {
    let collectionVC = FeedCollectionViewController()
    private var page = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionVC.show(in: self)
        collectionVC.pageSize = 10
        collectionVC.didSelect = {
            [weak self] in
            self?.goDetail(with: $0)
        }
        collectionVC.loadMore = {
            [weak self] in
            self?.loadNextPage()
        }
        reloadData()
    }

    func reloadData() {
        Task {
            await initData()
        }
    }

    func initData() async {
        page = 1
        collectionVC.displayDatas = (try? await requestData(page: 1)) ?? []
    }

    func loadNextPage() {
        Task {
            do {
                let data = try await requestData(page: page + 1)
                collectionVC.appendData(displayData: data)
                page += 1
            } catch let err {
                print(err)
            }
        }
    }

    func requestData(page: Int) async throws -> [any DisplayData] {
        let json = try await WebRequest.requestJSON(url: "https://api.bilibili.com/x/web-feed/feed?ps=40&pn=\(page)")

        let datas = json.arrayValue.map { data -> (any DisplayData) in
            let timestamp = data["pubdate"].int
            let date = DateFormatter.stringFor(timestamp: timestamp)
            let bangumi = data["bangumi"]
            if !bangumi.isEmpty {
                let season = bangumi["season_id"].intValue
                let owner = bangumi["title"].stringValue
                let pic = bangumi["cover"].url!
                let ep = bangumi["new_ep"]
                let title = "第" + ep["index"].stringValue + "集 - " + ep["index_title"].stringValue
                let episode = ep["episode_id"].intValue
                return BangumiData(title: title, season: season, episode: episode, ownerName: owner, pic: pic, date: date)
            }
            let avid = data["id"].intValue
            let archive = data["archive"]
            let title = archive["title"].stringValue
            let cid = archive["cid"].intValue
            let owner = archive["owner"]["name"].stringValue
            let avatar = archive["owner"]["face"].url
            let pic = archive["pic"].url!
            return FeedData(title: title, cid: cid, aid: avid, ownerName: owner, pic: pic, avatar: avatar, date: date)
        }
        return datas
    }

    func goDetail(with displayData: any DisplayData) {
        if let feed = displayData as? FeedData {
            let detailVC = VideoDetailViewController.create(aid: feed.aid, cid: feed.cid)
            detailVC.present(from: self)
            return
        }
        if let bangumi = displayData as? BangumiData {
            let detailVC = VideoDetailViewController.create(epid: bangumi.episode)
            detailVC.present(from: self)
        }
    }
}

struct FeedData: DisplayData {
    let title: String
    let cid: Int
    let aid: Int
    let ownerName: String
    let pic: URL?
    let avatar: URL?
    let date: String?
}

struct BangumiData: DisplayData {
    let title: String
    let season: Int
    let episode: Int
    let ownerName: String
    let pic: URL?
    let date: String?
}
