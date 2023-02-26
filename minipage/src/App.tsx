import React, { useEffect, useState } from 'react';
import logo from './assets/logo.png';
import './App.css';
import Button from '@mui/material/Button';
import { AppBar, Box, Container, Grid, IconButton, Paper, styled, Toolbar, Typography } from '@mui/material';
import { color } from '@mui/system';
import MenuIcon from '@mui/icons-material/Menu';
import Card from '@mui/material/Card';
import CardActions from '@mui/material/CardActions';
import CardContent from '@mui/material/CardContent';

import { EspressoMachineState, State } from './models/state';

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
uri = "http://192.168.178.98:8888";



const App = () => {
    const [state, setState] = useState<State>();
    const [timerId, setTimerId] = useState<NodeJS.Timer>();


    // getState();
    useEffect(() => {
        getState();
    }, []);

    useEffect(() => {
        const timerId = setInterval(() => getState(), 1000);
        setTimerId(timerId);
        return () => {
            console.log('Clean Timer');
            clearInterval(timerId);
        }
    }, []);

    return (
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
                    <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
                        despresso
                    </Typography>
                    {/* <Button color="inherit">Login</Button> */}
                </Toolbar>
            </AppBar>
            <br></br>
            <Container>
                <Grid container spacing={2}>
                    <Grid item xs={6}>
                        <Card sx={{ minWidth: 275 }}>
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
                </Grid>
            </Container>
        </Box >
    );

    function getState() {
        fetch(uri + "/api/state", {
            method: "GET"
        })
            .then((response) => {
                console.log("Resp:", response);
                return response.json();
            })
            .then((data) => {
                console.log("Response", data);
                setState(State.fromRaw(data));
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
                console.log("Resp:", response);
                return response.json();
            })
            .then((data) => {
                console.log("Response", data);
                setState(State.fromRaw(data));
            })
            .catch((err) => {
                console.log(err.message);
            });
    }
}

export default App;
