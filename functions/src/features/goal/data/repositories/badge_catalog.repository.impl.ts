import * as admin from "firebase-admin";
import {
    BadgeCatalogDocument,
    IBadgeCatalogRepository,
} from "../../domain/repositories/badge_catalog.repository";

/** Caminho do catálogo público de badges. */
export const BADGE_CATALOG_PATH = "config/badges";

export class BadgeCatalogRepositoryImpl implements IBadgeCatalogRepository {
    constructor(private firestore: admin.firestore.Firestore = admin.firestore()) {}

    private docRef() {
        return this.firestore.doc(BADGE_CATALOG_PATH);
    }

    async getPublishedVersion(): Promise<string | null> {
        const doc = await this.docRef().get();
        if (!doc.exists) {
            return null;
        }
        const version = doc.data()?.version;
        return typeof version === "string" ? version : null;
    }

    async publish(catalog: BadgeCatalogDocument): Promise<void> {
        // `set` sem merge: o catálogo é substituído por inteiro, então um badge
        // removido do código some do documento em vez de sobreviver para sempre.
        await this.docRef().set({
            ...catalog,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    }
}
