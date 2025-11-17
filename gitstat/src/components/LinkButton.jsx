import BlueButton from "./BlueButton";
import chainRight from '../images/chainRight.png'
import chainLeft from '../images/chainLeft.png'

function LinkButton({callback, ...props}){
    return(
        <BlueButton onClick={callback} {...props}>
            <div className="chain-container">
                <img src={chainLeft} className="chain-left" style={{ height: 27 }} />
                <img src={chainRight} className="chain-right" style={{ height: 27 }} />
            </div>
            <style>
                {`
                .chain-container {
                    position: relative;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                }

                .chain-left, .chain-right {
                    transition: transform 0.3s ease-in-out;
                }

                .chain-left {
                    position: relative;
                    transform: translateY(4px) translateX(1px);
                    z-index: 1;
                }

                .chain-right {
                    position: relative;
                    transform: translateY(-4px) translateX(-1px);
                    margin-left: -10px;
                    z-index: 2;
                }

                .blue-button:hover .chain-left {
                    transform: translate(-2px, 5px);
                }

                .blue-button:hover .chain-right {
                    transform: translate(2px, -5px);
                }
                `}
            </style>
        </BlueButton>
    )
}

export default LinkButton;