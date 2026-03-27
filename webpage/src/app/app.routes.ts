
import { Routes } from '@angular/router';
import {HomeComponent} from './pages/home/home.component';
import {SettingsComponent} from './pages/settings/settings.component';
import {ProfilesComponent} from './pages/profiles/profiles.component';
import {ShotSelectionComponent} from './pages/shot-selection/shot-selection.component';

export const routes: Routes = [
    {path: '', component: HomeComponent},
    {path: 'home', component: HomeComponent},
    {path: 'profiles', component: ProfilesComponent},
    {path: 'settings', component: SettingsComponent},
    {path: 'shots', component: ShotSelectionComponent},
    {path: '**', redirectTo: ''},
];
