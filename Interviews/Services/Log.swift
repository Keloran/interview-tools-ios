//
//  Log.swift
//  Interviews
//

import OSLog

/// Unified logging instead of print, so messages show in Console with a subsystem and stay out of release noise
let appLog = Logger(subsystem: "tools.interviews.ios", category: "app")
