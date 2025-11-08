//
//  SerializableContact.swift
//  AI Cleaner
//
//  Codable contact model for JSON backup
//

import Foundation
import Contacts

struct SerializableContact: Codable {
    let identifier: String?
    let givenName: String
    let familyName: String
    let organizationName: String
    let phoneNumbers: [PhoneNumber]
    let emailAddresses: [String]
    let postalAddresses: [PostalAddress]
    let birthday: Date?

    struct PhoneNumber: Codable {
        let label: String?
        let number: String
    }

    struct PostalAddress: Codable {
        let label: String?
        let street: String
        let city: String
        let state: String
        let postalCode: String
        let country: String
    }

    // Convert from CNContact
    init(from contact: CNContact) {
        self.identifier = contact.identifier
        self.givenName = contact.givenName
        self.familyName = contact.familyName
        self.organizationName = contact.organizationName

        self.phoneNumbers = contact.phoneNumbers.map { labeledValue in
            PhoneNumber(
                label: labeledValue.label,
                number: labeledValue.value.stringValue
            )
        }

        self.emailAddresses = contact.emailAddresses.map { $0.value as String }

        self.postalAddresses = contact.postalAddresses.map { labeledValue in
            let address = labeledValue.value
            return PostalAddress(
                label: labeledValue.label,
                street: address.street,
                city: address.city,
                state: address.state,
                postalCode: address.postalCode,
                country: address.country
            )
        }

        if let birthday = contact.birthday {
            let calendar = Calendar.current
            var components = DateComponents()
            components.year = birthday.year ?? 2000
            components.month = birthday.month ?? 1
            components.day = birthday.day ?? 1
            self.birthday = calendar.date(from: components)
        } else {
            self.birthday = nil
        }
    }

    // Convert to CNMutableContact
    func toCNContact() -> CNMutableContact {
        let contact = CNMutableContact()
        contact.givenName = givenName
        contact.familyName = familyName
        contact.organizationName = organizationName

        contact.phoneNumbers = phoneNumbers.map { phone in
            CNLabeledValue(
                label: phone.label,
                value: CNPhoneNumber(stringValue: phone.number)
            )
        }

        contact.emailAddresses = emailAddresses.map { email in
            CNLabeledValue(label: CNLabelHome, value: email as NSString)
        }

        contact.postalAddresses = postalAddresses.map { address in
            let cnAddress = CNMutablePostalAddress()
            cnAddress.street = address.street
            cnAddress.city = address.city
            cnAddress.state = address.state
            cnAddress.postalCode = address.postalCode
            cnAddress.country = address.country

            return CNLabeledValue(label: address.label, value: cnAddress)
        }

        if let birthday = birthday {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day], from: birthday)
            contact.birthday = components
        }

        return contact
    }
}

struct ContactsBackupData: Codable {
    let version: String
    let createdAt: Date
    let contacts: [SerializableContact]
}
