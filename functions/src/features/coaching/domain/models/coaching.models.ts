export enum CoachingType {
    insight = "insight",
    warning = "warning",
    tip = "tip",
}

export interface SlideModel {
    title: string;
    message: string;
    icon: string;
    color: string;
}

export interface CoachingModel {
    id: string;
    message: string;
    date: Date;
    type: CoachingType;
    slides: SlideModel[];
}
