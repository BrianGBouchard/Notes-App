//
//  NoteCell.swift
//  NotesApp
//
//  Created by Brian Bouchard on 11/14/18.
//  Copyright © 2018 Brian Bouchard. All rights reserved.
//

import Foundation
import UIKit

class NoteCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var updateTimeLabel: UILabel!

    var stringID: String?

}
