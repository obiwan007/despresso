import React, { useEffect, useState } from 'react';
import logo from './assets/logo.png';
import './App.css';
import Button from '@mui/material/Button';
import { AppBar, Box, Container, createTheme, CssBaseline, Grid, IconButton, Paper, styled, ThemeProvider, Toolbar, Typography } from '@mui/material';
import { color } from '@mui/system';
import MenuIcon from '@mui/icons-material/Menu';
import Card from '@mui/material/Card';
import CardActions from '@mui/material/CardActions';
import CardContent from '@mui/material/CardContent';

import { EspressoMachineState, Shot, State } from './models/state';

const Item = styled(Paper)(({ theme }) => ({
    backgroundColor: theme.palette.mode === 'dark' ? '#1A2027' : '#fff',
    ...theme.typography.body2,
    padding: theme.spacing(2),
    textAlign: 'center',
    color: theme.palette.text.secondary,
}));

const bull = (
    <Box
        component="span"
        sx={{ display: 'inline-block', mx: '2px', transform: 'scale(0.8)' }}
    >
        •
    </Box>
);

let uri = window.location.origin;
console.log("Origin", uri);

// Only for debugging
if (uri.startsWith("http://localhost:300")) {
    uri = "http://192.168.178.98:8888";
}

const darkTheme = createTheme({
    palette: {
        mode: 'dark',
        primary: {
            main: '#FFC000',
        },
        secondary: {
            main: '#FF7756',
        },
    },
});

const App = () => {
    const [state, setState] = useState<State>();
    const [shot, setShot] = useState<Shot>();
    const [timerId, setTimerId] = useState<NodeJS.Timer>();

    useEffect(() => {
        getState();
    }, []);

    useEffect(() => {
        const t = setInterval(() => {
            getState();
            getShot();
        }, 1000);
        setTimerId(t);
        return () => {
            console.log('Clean Timer');
            clearInterval(timerId);
        }
    }, []);

    return (
        <ThemeProvider theme={darkTheme}>
            <CssBaseline />
            <Box sx={{ flexGrow: 1 }}>
                <AppBar position="static">
                    <Toolbar>
                        <IconButton
                            size="large"
                            edge="start"
                            color="inherit"
                            aria-label="menu"
                            sx={{ mr: 2 }}
                        >
                            <MenuIcon />
                        </IconButton>
                        <img height="40px" src={logo}></img>

                        {/* <Button color="inherit">Login</Button> */}
                    </Toolbar>
                </AppBar>
                <br></br>

                <Container>
                    <Grid container spacing={2}>
                        <Grid item xs={6}>

                            <Card >
                                <CardContent>
                                    <ul>
                                        <li>
                                            {state?.state}
                                        </li>
                                        {(state?.subState !== "no_state" && state?.subState !== "") &&
                                            <li>
                                                {state?.subState}
                                            </li>
                                        }
                                    </ul>
                                </CardContent>
                                <CardActions>
                                    {(state?.state === EspressoMachineState.idle) &&
                                        <Button onClick={() => setMachineState(EspressoMachineState.sleep)}>Switch off</Button>
                                    }
                                    {(state?.state === EspressoMachineState.sleep) &&
                                        <Button onClick={() => setMachineState(EspressoMachineState.idle)}>Switch on</Button>
                                    }
                                    <Button onClick={() => getState()}>Get State</Button>
                                </CardActions>
                            </Card>
                        </Grid>
                        <Grid item xs={6}>

                            <Card >
                                <Grid container spacing={2}>
                                    <Grid item xs={6}>
                                        <CardContent>

                                            <Typography variant="caption" color="text.secondary" gutterBottom>
                                                Head temp
                                            </Typography>
                                            <Typography variant="body1" color="text.primary" gutterBottom>
                                                {shot?.headTemp.toFixed(1)} °C
                                            </Typography>

                                            <Typography variant="caption" color="text.secondary" gutterBottom>
                                                Set group pressure
                                            </Typography>
                                            <Typography variant="body1" color="text.primary" gutterBottom>
                                                {shot?.setGroupPressure.toFixed(1)} bar
                                            </Typography>

                                            <Typography variant="caption" color="text.secondary" gutterBottom>
                                                Flow
                                            </Typography>
                                            <Typography variant="body1" color="text.primary" gutterBottom>
                                                {shot?.groupFlow.toFixed(1)} ml/s
                                            </Typography>
                                        </CardContent>
                                    </Grid>
                                    <Grid item xs={6}>
                                        <CardContent>


                                            <Typography variant="caption" color="text.secondary" gutterBottom>
                                                Mix temp
                                            </Typography>
                                            <Typography variant="body1" color="text.primary" gutterBottom>
                                                {shot?.mixTemp.toFixed(1)} °C
                                            </Typography>
                                            <Typography variant="caption" color="text.secondary" gutterBottom>
                                                Current group pressure
                                            </Typography>
                                            <Typography variant="body1" color="text.primary" gutterBottom>
                                                {shot?.groupPressure.toFixed(1)} bar
                                            </Typography>
                                            <Typography variant="caption" color="text.secondary" gutterBottom>
                                                Weight
                                            </Typography>
                                            <Typography variant="body1" color="text.primary" gutterBottom>
                                                {shot?.weight.toFixed(1)} g
                                            </Typography>
                                        </CardContent>
                                    </Grid>
                                </Grid>



                            </Card>
                        </Grid>
                    </Grid>
                </Container>
            </Box >
        </ThemeProvider>
    );

    function getState() {
        fetch(uri + "/api/state", {
            method: "GET"
        })
            .then((response) => {
                return response.json();
            })
            .then((data) => {
                setState(State.fromRaw(data));
            })
            .catch((err) => {
                console.log(err.message);
            });
    }

    function getShot() {
        fetch(uri + "/api/shot", {
            method: "GET"
        })
            .then((response) => {
                return response.json();
            })
            .then((data) => {
                setShot(Shot.fromRaw(data));
            })
            .catch((err) => {
                console.log(err.message);
            });
    }

    function setMachineState(state: EspressoMachineState) {
        const s = new State();
        s.state = state;
        fetch(uri + "/api/state", {
            method: "POST",
            body: JSON.stringify(s),

        })
            .then((response) => {
                return response.json();
            })
            .then((data) => {
                setState(State.fromRaw(data));
            })
            .catch((err) => {
                console.log(err.message);
            });
    }
}

export default App;
