// SPDX-License-Identifier: GNU GPL

pragma solidity ^0.8.7;
import "./Ownable.sol";


contract Preferundum is Ownable{

    uint ProposalTime = 7 days ; // Time where people can answer the question 
    uint DecisionTime = 3 days ; // Time where people can answer the question 

    struct Governance {
        string question ; // Question for the governance
        string[] subject ; // Array of subject
        string[][]  possibilities ; // Array of possibilities
        uint id; // id of the question  
        uint date ; //  date when the proposition was ask
        address  ownerr;
    }


    struct Response {
        uint id; // the response for the proposition with id
        uint[] percentagesubject; // allocation of token about subject
        uint[][] percentage; // allocation of token for each proposition
        uint nbtoken;
        address payable  addressvote;
    }

    struct FinalProposition {
        string[]  possibilities ; // Array of possibilities
        uint id; // id of the question  
    }

    Governance[] public governances ;
    Response[] public  responses ; 
    bool stopeverything = false; // indicator of if the preferundum and referundum is stopped by the creator

    function proposequestion (string memory _question, string[] memory _subject, string[][] memory _possibilities) public  { // id is the id of the proposal
         uint _id = governances.length; // numero of the proposition
         uint _date = block.timestamp ; 
        governances.push(Governance(_question, _subject, _possibilities , _id , _date, msg.sender));
    }

    function stopgovernance (uint _id) public returns(bool) {
        require(block.timestamp - governances[_id].date > ProposalTime+DecisionTime);
        
        if (governances[_id].ownerr == msg.sender){
            stopeverything = true;
        } 
        return stopeverything;
    }
    
    function answerquestion (uint[] memory _percentagesubject, uint[][] memory _percentage, uint _id, uint _nbtoken ) public payable  {
        require(msg.value==_nbtoken);
        if (stopgovernance(_id)==false){
            uint goodpercentage =0 ;
            uint goodpercentagesubject = 0;
            for (uint j=0 ; j<_percentagesubject.length ; j++){
                for (uint i=0; i<_percentage[j].length;i++){
                    goodpercentage = goodpercentage + _percentage[j][i];
                }
            }

            for (uint i=0; i<_percentagesubject.length;i++){
                goodpercentagesubject = goodpercentagesubject + _percentagesubject[i];
            }
            require (goodpercentage == 1*_percentagesubject.length); 
            require (goodpercentagesubject == 1); 
            if(block.timestamp - governances[_id].date < ProposalTime){
                 responses.push(Response(_id, _percentagesubject,_percentage, _nbtoken,payable(msg.sender)));
            }
        }

    }

    function addpossibilities (string memory _proposition , uint _numbersubject , uint _id) public {
        if (stopgovernance(_id)==false){
            governances[_id].possibilities[_numbersubject].push(_proposition);
        }
    }

    function getbacktoken (uint _id)   public payable onlyOwner{
        for (uint i=0 ; i<responses.length ; i++){
            if(responses[i].id==_id){
                responses[i].addressvote.transfer(responses[i].nbtoken);
            }
        }
    }

    function propositionchosen(uint _id) public  returns  (FinalProposition memory) {
        require(stopgovernance(_id)==false);
        require(block.timestamp - governances[_id].date > ProposalTime);
        uint[][] memory count;      
        string[] memory possibilitieschosen ;

        for (uint i=0 ; i<responses.length ; i++){ // calcul of token for each proposition of each subject
            if(responses[i].id == _id){
                for(uint j=0 ; j<responses[i].percentagesubject.length ; j++){
                    for ( uint k=0 ; k<responses[i].percentage[j].length ; k++){
                        count[j][k] = count[j][k] + responses[i].percentage[j][k]*responses[i].percentagesubject[j]*responses[i].nbtoken;
                    }
                }
            }

        }
        uint[] memory numberchoice ; 
        for(uint j=0 ; j<responses[j].percentagesubject.length ; j++){
            uint stockmax =0;
            for (uint k=0 ; k<governances[_id].subject.length; k++){
                if(count[j][k]>stockmax){
                    stockmax = count[j][k];
                }else{
                    numberchoice[j] = k;
                }
            }
        }

        for(uint i=0 ; i<governances[_id].subject.length ; i++){
            possibilitieschosen[i]=governances[_id].possibilities[i][numberchoice[i]];
        }

        getbacktoken(_id);
        return (FinalProposition(possibilitieschosen,_id));
    }


}
